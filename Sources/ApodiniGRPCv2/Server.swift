import Apodini
import ApodiniExtension
import NIO
import NIOHPACK
import Foundation
import ApodiniUtils
import ApodiniNetworking
import ProtobufferCoding



struct GRPCv2ServerError: Swift.Error {
    let message: String
}


/// The gRPC server manages a set of gRPC services (as well as their methods),
/// and implements the logic for handling incoming requests to these methods.
class GRPCv2Server {
    private(set) var services: [GRPCService] = [] // TODO make this a dict? would that improve performance?
    
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
    
    
    @discardableResult
    func createService(name: String, associatedWithPackage packageName: String) -> GRPCService {
        precondition(service(named: name, inPackage: packageName) == nil, "gRPC service names must be unique")
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
    func makeStreamRPCHandler(toService serviceNameString: String, method: String) -> GRPCv2StreamRPCHandler? {
        let serviceNameComponents = serviceNameString.split(separator: ".")
        precondition(serviceNameComponents.count >= 2)
        let packageName = serviceNameComponents.dropLast().joined(separator: ".")
        let serviceName = String(serviceNameComponents.last!)
        guard let service = service(named: serviceName, inPackage: packageName), let method = service.method(named: method) else {
            return nil
        }
        return method.makeStreamConnectionContext()
    }
    
    
    // TODO move this to the schema?
    func createFileDescriptors() {
        // We currently have only two hard-coded file descriptors: the reflection service, and the actual web service
        let fileDescriptors = [
            makeFileDescriptorProto(
                forPackage: "google.protobuf", // This only works because the only types we declare w/ this package name are the types found in descriptors.proto
                name: "google/protobuf/descriptor.proto"
            ),
            makeFileDescriptorProto(
                forPackage: GRPCv2InterfaceExporter.serverReflectionPackageName,
                name: "grpc_reflection/v1alpha/reflection.proto",
                dependencies: [
                    "google/protobuf/descriptor.proto"
                ] // TODO?
            ),
            makeFileDescriptorProto(
                forPackage: defaultPackageName,
                name: "\(defaultPackageName).proto",
                dependencies: [] // TODO?
            )
        ]
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
            "gRPC method names must be unique within a service"
        )
        method.packageName = self.packageName
    }
    
    func method(named methodName: String) -> GRPCMethod? {
        methodsByName[methodName]
    }
}



class GRPCMethod {
    let name: String
    fileprivate(set) var packageName: String? // Nil until the method is added to a service
    let type: CommunicationalPattern
    let inputFQTN: String
    let outputFQTN: String
    private let streamRPCHandlerMaker: () -> GRPCv2StreamRPCHandler
    
    init<H: Handler>(
        name: String,
        endpoint: Endpoint<H>,
        endpointContext: GRPCv2EndpointContext,
        decodingStrategy: AnyDecodingStrategy<GRPCv2MessageIn>,
        schema: ProtoSchema
    ) {
        self.name = name
        self.type = endpoint[CommunicationalPattern.self]
        
        // TODO is it important that we do the defaults load only once, instead of every time a connection is opened?
        let defaults = endpoint[DefaultValueStore.self]
        
        self.streamRPCHandlerMaker = { () -> GRPCv2StreamRPCHandler in
            let rpcHandlerType: StreamRPCHandlerBase<H>.Type = {
                switch endpoint[CommunicationalPattern.self] {
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
                delegateFactory: endpoint[DelegateFactory<H, GRPCv2InterfaceExporter>.self],
                strategy: decodingStrategy,
                defaults: defaults,
                endpointContext: endpointContext
            )
        }
        let messageTypes = try! schema.endpointProtoMessageTypes(for: endpoint)
        endpointContext.endpointRequestType = messageTypes.input
        endpointContext.endpointResponseType = messageTypes.output
        self.inputFQTN = messageTypes.input.fullyQualifiedTypename // TODO we can remove the xFQTN properties!!!
        self.outputFQTN = messageTypes.output.fullyQualifiedTypename
    }
    
    
    init(name: String, type: CommunicationalPattern, inputFQTN: String, outputFQTN: String, streamRPCHandlerMaker: @escaping () -> GRPCv2StreamRPCHandler) {
        self.name = name
        self.type = type
        self.inputFQTN = inputFQTN
        self.outputFQTN = outputFQTN
        self.streamRPCHandlerMaker = streamRPCHandlerMaker
    }
    
    
    func makeStreamConnectionContext() -> GRPCv2StreamRPCHandler {
        streamRPCHandlerMaker()
    }
}


extension FileDescriptorProto {
    func computeAllSymbols() -> Set<String> {
        var symbols = Set<String>()
        if self.package.isEmpty {
            symbols.formUnion(services.map(\.name))
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
