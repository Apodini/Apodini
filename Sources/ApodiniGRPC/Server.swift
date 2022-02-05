//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniExtension
import NIO
import NIOHPACK
import Foundation
import ApodiniUtils
import ApodiniNetworking
import ProtobufferCoding


struct GRPCServerError: Swift.Error {
    let message: String
}


/// The gRPC server manages a set of gRPC services (as well as their methods),
/// and implements the logic for handling incoming requests to these methods.
class GRPCServer {
    private(set) var services: [GRPCService] = []
    private(set) var fileDescriptors: [(symbols: Set<String>, fileDescriptor: FileDescriptorProto)] = []
    
    let defaultPackageName: String
    let schema: ProtoSchema
    
    init(defaultPackageName: String) {
        self.defaultPackageName = defaultPackageName
        self.schema = .init(defaultPackageName: defaultPackageName)
    }
    
    func service(named serviceName: String, inPackage packageName: String) -> GRPCService? {
        services.first { $0.packageName == packageName && $0.name == serviceName }
    }
    
    func hasService(named serviceName: String, inPackage packageName: String) -> Bool {
        service(named: serviceName, inPackage: packageName) != nil
    }
    
    @discardableResult
    func createService(name: String, associatedWithPackage packageName: String) -> GRPCService {
        precondition(!hasService(named: name, inPackage: packageName), "gRPC service names must be unique")
        let service = GRPCService(name: name, packageName: packageName)
        services.append(service)
        return service
    }
    
    func addMethod(toServiceNamed serviceName: String, inPackage packageName: String, _ method: GRPCMethod) {
        guard let service = service(named: serviceName, inPackage: packageName) else {
            fatalError("No service with name '\(serviceName)' registered")
        }
        service.addMethod(method)
    }
    
    /// - returns: `nil` if the service/method was not found
    func makeStreamRPCHandler(toService serviceNameString: String, method: String) -> GRPCStreamRPCHandler? {
        let serviceNameComponents = serviceNameString.split(separator: ".")
        precondition(serviceNameComponents.count >= 2)
        let packageName = serviceNameComponents.dropLast().joined(separator: ".")
        let serviceName = String(serviceNameComponents.last!)
        guard let service = service(named: serviceName, inPackage: packageName), let method = service.method(named: method) else {
            return nil
        }
        return method.makeStreamConnectionContext()
    }
    
    
    func createFileDescriptors() {
        let fileDescriptors: [FileDescriptorProto] = schema.finalizedPackages.map { packageName, packageInfo in
            makeFileDescriptorProto(forPackage: packageName, packageInfo: packageInfo)
        }
        self.fileDescriptors = fileDescriptors.map {
            ($0.computeAllSymbols(), $0)
        }
    }
    
    func fileDescriptor(forFilename filename: String) -> FileDescriptorProto? {
        fileDescriptors.first { $0.fileDescriptor.name == filename }?.fileDescriptor
    }
    
    func fileDescriptor(forSymbol symbol: String) -> FileDescriptorProto? {
        fileDescriptors.first { $0.symbols.contains(symbol) }?.fileDescriptor
    }
    
    
    func makeFileDescriptorProto(
        forPackage packageUnit: ProtobufPackageUnit,
        packageInfo: ProtoSchema.FinalizedPackage
    ) -> FileDescriptorProto {
        precondition(packageUnit == packageInfo.packageUnit)
        var referencedSymbols: Set<String> = packageInfo.referencedSymbols
        var fdProto = FileDescriptorProto(
            name: packageUnit.filename,
            package: packageUnit.packageName,
            dependencies: [],
            publicDependency: [],
            weakDependency: [],
            messageTypes: packageInfo.messageTypes,
            enumTypes: packageInfo.enumTypes,
            services: services.compactMap { service -> ServiceDescriptorProto? in
                guard service.packageName == packageUnit.packageName else {
                    return nil
                }
                return ServiceDescriptorProto(
                    name: service.name,
                    methods: service.methods.map { method -> MethodDescriptorProto in
                        referencedSymbols.insert(method.inputType.fullyQualifiedTypename)
                        referencedSymbols.insert(method.outputType.fullyQualifiedTypename)
                        return MethodDescriptorProto(
                            name: method.name,
                            inputType: method.inputType.fullyQualifiedTypename,
                            outputType: method.outputType.fullyQualifiedTypename,
                            options: nil,
                            clientStreaming: method.type == .clientSideStream || method.type == .bidirectionalStream,
                            serverStreaming: method.type == .serviceSideStream || method.type == .bidirectionalStream,
                            sourceCodeComments: method.sourceCodeComments
                        )
                    },
                    // NOTE: we could use this to mark services as deprecated. might be interesting in combination with the migration stuff...
                    options: nil
                )
            },
            extensions: [],
            options: nil,
            sourceCodeInfo: nil,
            syntax: packageInfo.packageSyntax.rawValue
        )
        fdProto.dependencies = referencedSymbols
            .compactMapIntoSet { symbolName -> String? in
                /// Name of the package in which the referenced file resides
                let packageUnit: ProtobufPackageUnit? = schema.fqtnByPackageMapping.first { $1.contains(symbolName) }?.key
                if packageUnit == packageInfo.packageUnit {
                    // packageInfo is the package for which we're asked to produce a file descriptor.
                    // so, if the referenced type is in the current package, we can skip it.
                    return nil
                }
                return packageUnit?.filename
            }
            .intoArray()
        return fdProto
    }
}


class GRPCService {
    let name: String
    let packageName: String
    private var methodsByName: [String: GRPCMethod] = [:]
    
    var methods: Dictionary<String, GRPCMethod>.Values {
        methodsByName.values
    }
    
    init(name: String, packageName: String, methods: [GRPCMethod] = []) {
        self.name = name
        self.packageName = packageName
        for method in methods {
            addMethod(method)
        }
    }
    
    func addMethod(_ method: GRPCMethod) {
        precondition(
            methodsByName.updateValue(method, forKey: method.name) == nil,
            "gRPC method names must be unique within a service. Encountered multiple methods for name '\(method.name)'"
        )
        method.packageName = self.packageName
    }
    
    func method(named methodName: String) -> GRPCMethod? {
        methodsByName[methodName]
    }
    
    func hasMethod(named methodName: String) -> Bool {
        method(named: methodName) != nil
    }
}


class GRPCMethod {
    /// The name of the method, as exposed to clients
    let name: String
    /// Name of the proto package to which the service this method is a part of belongs.
    /// - Note: This property is `nil` until the method is added to a service. Then it is set to the service's package.
    fileprivate(set) var packageName: String?
    /// The method's communication pattern, e.g. unary, client-side-streaming, etc
    let type: CommunicationPattern
    /// The method's input proto type. This is guaranteed to be a top-level type.
    let inputType: ProtoType
    /// The method's output proto type. This is guaranteed to be a top-level type.
    let outputType: ProtoType
    /// Closure that makes a `GRPCStreamRPCHandler`
    private let streamRPCHandlerMaker: () -> GRPCStreamRPCHandler
    let sourceCodeComments: [String]
    
    init<H: Handler>(
        name: String,
        endpoint: Endpoint<H>,
        endpointContext: GRPCEndpointContext,
        decodingStrategy: AnyDecodingStrategy<GRPCMessageIn>,
        schema: ProtoSchema,
        sourceCodeComments: [String] = []
    ) {
        self.name = name
        self.type = endpoint[CommunicationPattern.self]
        
        let defaults = endpoint[DefaultValueStore.self]
        self.streamRPCHandlerMaker = { () -> GRPCStreamRPCHandler in
            let rpcHandlerType: StreamRPCHandlerBase<H>.Type = {
                switch endpoint[CommunicationPattern.self] {
                case .requestResponse:
                    return UnaryRPCHandler.self
                case .clientSideStream:
                    return ClientSideStreamRPCHandler.self
                case .serviceSideStream:
                    return ServiceSideStreamRPCHandler.self
                case .bidirectionalStream:
                    return BidirectionalStreamRPCHandler.self
                }
            }()
            return rpcHandlerType.init(
                delegateFactory: endpoint[DelegateFactory<H, GRPCInterfaceExporter>.self],
                strategy: decodingStrategy,
                defaults: defaults,
                errorForwarder: endpoint[ErrorForwarder.self],
                endpointContext: endpointContext
            )
        }
        let messageTypes = try! schema.informAboutEndpoint(endpoint, grpcMethodName: name)
        endpointContext.endpointRequestType = messageTypes.input
        endpointContext.endpointResponseType = messageTypes.output
        self.inputType = messageTypes.input
        self.outputType = messageTypes.output

        self.sourceCodeComments = sourceCodeComments
    }
    
    
    init(
        name: String,
        type: CommunicationPattern,
        inputType: ProtoType,
        outputType: ProtoType,
        streamRPCHandlerMaker: @escaping () -> GRPCStreamRPCHandler,
        sourceCodeComments: [String] = []
    ) {
        self.name = name
        self.type = type
        self.inputType = inputType
        self.outputType = outputType
        self.streamRPCHandlerMaker = streamRPCHandlerMaker
        self.sourceCodeComments = sourceCodeComments
    }
    
    
    func makeStreamConnectionContext() -> GRPCStreamRPCHandler {
        streamRPCHandlerMaker()
    }
}


extension FileDescriptorProto {
    func computeAllSymbols() -> Set<String> {
        var symbols = Set<String>()
        if self.package.isEmpty {
            symbols.formUnion(services.map(\.name))
            symbols.formUnion(services.flatMap(\.methods).map(\.name))
            symbols.formUnion(enumTypes.map(\.name))
        } else {
            symbols.formUnion(services.map { "\(self.package).\($0.name)" })
            symbols.formUnion(enumTypes.map { "\(self.package).\($0.name)" })
        }
        for type in messageTypes {
            type.collectSymbols(into: &symbols, keyPath: self.package.isEmpty ? [] : [self.package])
        }
        return symbols
    }
}

extension DescriptorProto {
    fileprivate func collectSymbols(into symbolsSet: inout Set<String>, keyPath: [String]) {
        let newKeyPath = keyPath.appending(self.name)
        symbolsSet.insert(newKeyPath.joined(separator: "."))
        for type in enumTypes {
            symbolsSet.insert(newKeyPath.appending(type.name).joined(separator: "."))
        }
        for type in nestedTypes {
            type.collectSymbols(into: &symbolsSet, keyPath: newKeyPath)
        }
    }
}
