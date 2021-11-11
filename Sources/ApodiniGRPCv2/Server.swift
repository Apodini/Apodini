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
    let schema: GRPCv2SchemaManager
    
    init(defaultPackageName: String) {
        self.defaultPackageName = defaultPackageName
        self.schema = .init(defaultPackageName: defaultPackageName)
    }
    
    
    func service(named serviceName: String, inPackage packageName: String) -> GRPCService? {
        //services.first { name == "\($0.packageName).\($0.name)" }
        services.first { $0.packageName == packageName && $0.name == serviceName }
    }
    
    
    @discardableResult
    func createService(name: String, associatedWithPackage packageName: String) -> GRPCService {
        //precondition(!services.contains { $0.name == name }, "gRPC service names must be unique")
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
        schema: GRPCv2SchemaManager
    ) {
        self.name = name
        self.type = endpoint[CommunicationalPattern.self]
        
        // TODO is it important that we do the defaults load only once, instead of every time a connection is opened?
        let defaults = endpoint[DefaultValueStore.self]
        
        self.streamRPCHandlerMaker = { () -> GRPCv2StreamRPCHandler in
            switch endpoint[CommunicationalPattern.self] {
            case .requestResponse:
                return UnaryRPCHandler<H>(
                    delegateFactory: endpoint[DelegateFactory<H, GRPCv2InterfaceExporter>.self],
                    strategy: decodingStrategy,
                    defaults: defaults,
                    endpointContext: endpointContext
                )
            case .clientSideStream:
                fatalError()
            case .serviceSideStream:
                return ServiceSideStreamRPCHandler<H>(
                    delegateFactory: endpoint[DelegateFactory<H, GRPCv2InterfaceExporter>.self],
                    strategy: decodingStrategy,
                    defaults: defaults,
                    endpointContext: endpointContext
                )
            case .bidirectionalStream:
                fatalError()
            }
//            switch endpoint[CommunicationalPattern.self] {
//            case .requestResponse:
//                return _UnaryStreamRPCHandler<H>(
//                    delegateFactory: endpoint[DelegateFactory<H, GRPCv2InterfaceExporter>.self],
//                    strategy: decodingStrategy,
//                    defaults: defaults,
//                    endpointContext: endpointContext
//                )
//            case .clientSideStream:
//                fatalError()
//            case .serviceSideStream:
//                fatalError()
//            case .bidirectionalStream:
//                fatalError()
//            }
        }
//        let outTy = try! ApodiniTypeInformation.TypeInformation.init(type: H.Response.Content.self)
//        print(outTy)
//        fatalError()
        let messageTypes = try! schema.endpointProtoMessageTypes(for: endpoint)
        endpointContext.endpointRequestType = messageTypes.input
        endpointContext.endpointResponseType = messageTypes.output
        self.inputFQTN = messageTypes.input.fullyQualifiedTypename // TODO we can remove the xFQTN properties!!!
        self.outputFQTN = messageTypes.output.fullyQualifiedTypename
//        print("\n\n\n\n\n")
//        print("handler: \(endpoint.handler)")
//        print("messageTypes: \(messageTypes)")
//        self.inputFQTN = messageTypes.input.fullyQualifiedTypename
//        self.outputFQTN = messageTypes.output.fullyQualifiedTypename
//        //precondition(self.inputFQTN == endpointContext.endpointRequestType!.fullyQualifiedTypename)
//        switch messageTypes.input {
//        case let .compositeMessage(name, underlyingType: .none, nestedOneofTypes, fields):
//            let dict1: [String: Int] = .init(uniqueKeysWithValues: fields.map { ($0.name, $0.fieldNumber) })
//            precondition(dict1 == endpointContext.parameterNameFieldNumberMapping)
//        default:
//            break
//        }
//        precondition(self.outputFQTN == endpointContext.endpointResponseType!.fullyQualifiedTypename)
    }
    
    
    init(name: String, type: CommunicationalPattern, inputFQTN: String, outputFQTN: String, streamRPCHandlerMaker: @escaping () -> GRPCv2StreamRPCHandler) {
        self.name = name
        self.type = type
        self.inputFQTN = inputFQTN
        self.outputFQTN = outputFQTN
        self.streamRPCHandlerMaker = streamRPCHandlerMaker
    }
    
    
    // TODO this function isn't needed anymore!
    func makeStreamConnectionContext() -> GRPCv2StreamRPCHandler {
        streamRPCHandlerMaker()
    }
}




//// TODO move somewhere else
//extension FileDescriptorProto {
//    func containsSymbol(_ symbolName: String) -> Bool {
//        let components = symbolName.components(separatedBy: ".")
//        switch components.count {
//        case 1:
//            return services.contains { $0.name == symbolName }
//        case 2:
//            // syntax: package.type or package.service
//            return self.package == components[0] && (
//                services.contains { $0.name == components[1] }
//                || messageTypes.contains { $0.name == components[1] }
//                || enumTypes.contains { $0.name == components[1] }
//            )
//        case 3:
//            // syntax: package.service.method
//        }
//        fatalError()
//    }
//}


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
