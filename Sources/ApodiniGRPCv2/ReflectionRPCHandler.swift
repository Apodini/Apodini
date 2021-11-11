import Apodini
import Runtime
import ApodiniUtils
import Foundation
import NIOHPACK
import AssociatedTypeRequirementsVisitor
import ProtobufferCoding



// MARK: RPC Handler

class ServerReflectionInfoRPCHandler: GRPCv2StreamRPCHandler {
    private unowned let server: GRPCv2Server
    
    init(server: GRPCv2Server) {
        self.server = server
    }
    
    func handleStreamOpen(context: GRPCv2StreamConnectionContext) {}
    
    func handleStreamClose(context: GRPCv2StreamConnectionContext) {}
    
    func handle(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut> {
        let reflectionRequest: ReflectionRequest
        do {
            reflectionRequest = try ProtobufferDecoder().decode(ReflectionRequest.self, from: message.payload)
        } catch {
            // TODO return an error response
            fatalError("\(error)")
        }
        let reflectionResponse: ReflectionResponse
        switch reflectionRequest.messageRequest {
        case .fileByFilename(let filename):
            guard let fileDescriptor = server.fileDescriptor(forFilename: filename) else {
                fatalError()
            }
            reflectionResponse = ReflectionResponse(
                validHost: reflectionRequest.host,
                originalRequest: reflectionRequest,
                messageResponse: .fileDescriptorResponse(FileDescriptorResponse(fileDescriptors: [fileDescriptor]))
            )
        case .fileContainingSymbol(let symbol):
            guard let fileDescriptor = server.fileDescriptor(forSymbol: symbol) else {
                fatalError()
            }
            reflectionResponse = ReflectionResponse(
                validHost: reflectionRequest.host,
                originalRequest: reflectionRequest,
                messageResponse: .fileDescriptorResponse(FileDescriptorResponse(fileDescriptors: [fileDescriptor]))
            )
        case .fileContainingExtension:
            // We don't support extensions, so we simply always return an empty list of descriptors
            reflectionResponse = ReflectionResponse(
                validHost: reflectionRequest.host,
                originalRequest: reflectionRequest,
                messageResponse: .fileDescriptorResponse(FileDescriptorResponse(fileDescriptors: []))
            )
        case .allExtensionNumbersOfType:
            // gRPC's reflection.proto says that this should return the UNIMPLEMENTED status if a server doesn't implement it.
            reflectionResponse = ReflectionResponse(
                validHost: reflectionRequest.host,
                originalRequest: reflectionRequest,
                messageResponse: .errorResponse(ErrorResponse(
                    errorCode: Int32(GRPCv2Status.Code.unimplemented.rawValue),
                    errorMessage: "not implemented"
                ))
            )
        case .listServices:
            reflectionResponse = server.handleListServicesReflectionRequest(reflectionRequest)
        }
        let responsePayload: ByteBuffer
        do {
            responsePayload = try ProtobufferEncoder().encode(reflectionResponse)
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }
        assert({
            let decodedResponse = try! ProtobufferDecoder().decode(ReflectionResponse.self, from: responsePayload)
            return decodedResponse == reflectionResponse
        }())
        return context.eventLoop.makeSucceededFuture(.singleMessage(
            headers: HPACKHeaders {
                $0[.contentType] = .gRPC(.proto)
            },
            payload: responsePayload,
            closeStream: false
        ))
    }
    
    
    static func registerReflectionServiceTypesWithSchema(_ schema: ProtoSchema) {
        schema.informAboutMessageType(ReflectionRequest.self)
        schema.informAboutMessageType(ReflectionResponse.self)
    }
}




// MARK: Server Reflection Support

extension GRPCv2Server {
    fileprivate func handleMakeFileContainingSymbolRequest(_ reflectionRequest: ReflectionRequest, forSymbol symbolName: String) throws -> ReflectionResponse? {
        // Proto docs: (https://github.com/grpc/grpc/blob/master/src/proto/grpc/reflection/v1alpha/reflection.proto)
        //      Find the proto file that declares the given fully-qualified symbol name.
        //      This field should be a fully-qualified symbol name
        //      (e.g. <package>.<service>[.<method>] or <package>.<type>).
        // The main issue here is deconstructing the symbol into a service (and method) name. There's also that type thing???
        
        
        
        // Normally, this would look need to loop up the file containing the requested symbol.
        // Thing is, however, we don't actually have any files, so we instead just check whether
        // the symbol is known to the server, and, if it is, return the server's whole proto definition.
        
        let isKnownSymbol: Bool = { () -> Bool in
            let components = symbolName.components(separatedBy: ".")
            if components.count > 2 { // is this a `package.service.method` string?
                // Is the last component a method?
                let methodName = components.last!
                //let serviceName = components[0..<(components.endIndex - 1)].joined(separator: ".")
                let serviceName = components[components.endIndex - 2]
                let packageName = components[0..<(components.endIndex - 2)].joined(separator: ".")
                if let service = service(named: serviceName, inPackage: packageName), let _ = service.method(named: methodName) {
                    return true
                }
            }
            if components.count > 1 { // is this a `package.service` string?
                let serviceName = components.last!
                let packageName = components[0..<(components.endIndex - 1)].joined(separator: ".")
                if let _ = service(named: serviceName, inPackage: packageName) {
                    return true
                }
            }
            if services.contains(where: { $0.name == symbolName || $0.packageName == symbolName }) {
                return true
            }
            return false
        }()
        
        guard isKnownSymbol else {
            return nil
        }
        
        let reflectionDescriptor = makeFileDescriptorProto(
            forPackage: GRPCv2InterfaceExporter.serverReflectionPackageName,
            name: "grpc_reflection/v1alpha/reflection.proto"
        )
        
        let fileDescriptorResponse = FileDescriptorResponse(fileDescriptors: [
            makeFileDescriptorProto(forPackage: self.defaultPackageName, dependencies: [
                reflectionDescriptor.name,
                "google/protobuf/empty.proto" // TODO include this only when actually necessary!
            ])
        ])
        
        return ReflectionResponse(
            validHost: reflectionRequest.host, // TODO
            originalRequest: reflectionRequest,
            messageResponse: .fileDescriptorResponse(fileDescriptorResponse)
        )
    }
    
    
    fileprivate func handleListServicesReflectionRequest(_ reflectionRequest: ReflectionRequest) -> ReflectionResponse {
        ReflectionResponse(
            validHost: reflectionRequest.host, // TODO???
            originalRequest: reflectionRequest,
            messageResponse: .listServicesResponse(ListServiceResponse(
                services: services.map { ServiceResponse(name: "\($0.packageName).\($0.name)") }
            ))
        )
    }
    
    
    func makeFileDescriptorProto(forPackage packageName: String, name: String? = nil, outputPackageName: String? = nil, dependencies: [String] = []) -> FileDescriptorProto {
        return FileDescriptorProto(
            name: name ?? "\(packageName.replacingOccurrences(of: ".", with: "_")).proto",
            package: outputPackageName ?? packageName,
            dependencies: dependencies,
            publicDependency: [],
            weakDependency: [],
            messageTypes: schema.messageTypeDescriptors(forPackage: packageName),
            enumTypes: schema.enumTypeDescriptors(forPackage: packageName),
            services: services.compactMap { service -> ServiceDescriptorProto? in
                guard service.packageName == packageName else {
                    return nil
                }
                return ServiceDescriptorProto(
                    name: service.name,
                    methods: service.methods.map { method -> MethodDescriptorProto in
                        MethodDescriptorProto(
                            name: method.name,
                            inputType: method.inputFQTN,
                            outputType: method.outputFQTN,
                            options: nil,
                            clientStreaming: method.type == .clientSideStream || method.type == .bidirectionalStream,
                            serverStreaming: method.type == .serviceSideStream || method.type == .bidirectionalStream
                        )
                    },
                    options: nil // TODO use this to deprecate services? Add an option via a modifier?
                )
            },
            extensions: [],
            options: nil,
            sourceCodeInfo: nil,
            syntax: "proto3"
        )
    }
}




// MARK: Reflection Service Types
// Note: The reason all of these are in here instead of being in a spearate file
// is so that we can declare them as private and avoid cluttering the module namespace.

private protocol __ProtoNS_GRPC_Reflection_V1Alpha: ProtoTypeInPackage {}
extension __ProtoNS_GRPC_Reflection_V1Alpha {
    public static var package: ProtobufPackageName { .init("grpc.reflection.v1alpha") }
}


private struct ExtensionRequest: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let containingType: String
    let extensionNumber: Int32
    enum CodingKeys: Int, CodingKey {
        case containingType = 1
        case extensionNumber = 2
    }
}


private struct ReflectionRequest: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha, ProtoTypeWithCustomProtoName {
    static var protoTypename: String { "ServerReflectionRequest" }
    
    enum MessageRequest: ProtobufEnumWithAssociatedValues, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
        case fileByFilename(String)
        case fileContainingSymbol(String)
        case fileContainingExtension(ExtensionRequest)
        case allExtensionNumbersOfType(String)
        case listServices(String)
        
        enum CodingKeys: Int, CodingKey, CaseIterable, ProtobufMessageCodingKeys {
            case fileByFilename = 3
            case fileContainingSymbol = 4
            case fileContainingExtension = 5
            case allExtensionNumbersOfType = 6
            case listServices = 7
        }
        
        static func makeEnumCase(forCodingKey codingKey: CodingKeys, payload: Any?) -> ReflectionRequest.MessageRequest {
            switch codingKey {
            case .fileByFilename:
                return .fileByFilename(payload as! String)
            case .fileContainingSymbol:
                return .fileContainingSymbol(payload as! String)
            case .fileContainingExtension:
                return .fileContainingExtension(payload as! ExtensionRequest)
            case .allExtensionNumbersOfType:
                return .allExtensionNumbersOfType(payload as! String)
            case .listServices:
                return .listServices(payload as! String)
            }
        }
        
        var getCodingKeyAndPayload: (CodingKeys, Any?) {
            switch self {
            case .fileByFilename(let value):
                return (.fileByFilename, value)
            case .fileContainingSymbol(let value):
                return (.fileContainingSymbol, value)
            case .fileContainingExtension(let value):
                return (.fileContainingExtension, value)
            case .allExtensionNumbersOfType(let value):
                return (.allExtensionNumbersOfType, value)
            case .listServices(let value):
                return (.listServices, value)
            }
        }
    }
    
    let host: String
    let messageRequest: MessageRequest
    
    enum CodingKeys: Int, CodingKey {
        case host = 1
        case messageRequest = -1
    }
}



// MARK: ReflectionResponse


private struct FileDescriptorResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let fileDescriptors: [FileDescriptorProto]
    
    enum CodingKeys: Int, CodingKey {
        case fileDescriptors = 1
    }
}


private struct ExtensionNumberResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let baseTypeName: String
    let extensionNumber: [Int32]
    
    enum CodingKeys: Int, CodingKey {
        case baseTypeName = 1
        case extensionNumber = 2
    }
}


private struct ListServiceResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let services: [ServiceResponse]
    
    enum CodingKeys: Int, CodingKey {
        case services = 1
    }
}


private struct ServiceResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let name: String
    
    enum CodingKeys: Int, CodingKey {
        case name = 1
    }
}


private struct ErrorResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let errorCode: Int32
    let errorMessage: String
    
    enum CodingKeys: Int, CodingKey {
        case errorCode = 1
        case errorMessage = 2
    }
}

private struct ReflectionResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha, ProtoTypeWithCustomProtoName {
    static var protoTypename: String { "ServerReflectionResponse" }
    
    enum MessageResponse: ProtobufEnumWithAssociatedValues, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
        case fileDescriptorResponse(FileDescriptorResponse)
        case allExtensionNumbersResponse(ExtensionNumberResponse)
        case listServicesResponse(ListServiceResponse)
        case errorResponse(ErrorResponse)
        
        enum CodingKeys: Int, CodingKey, CaseIterable, ProtobufMessageCodingKeys {
            case fileDescriptorResponse = 4
            case allExtensionNumbersResponse = 5
            case listServicesResponse = 6
            case errorResponse = 7
        }
        
        static func makeEnumCase(forCodingKey codingKey: CodingKeys, payload: Any?) -> ReflectionResponse.MessageResponse {
            switch codingKey {
            case .fileDescriptorResponse:
                return .fileDescriptorResponse(payload as! FileDescriptorResponse)
            case .allExtensionNumbersResponse:
                return .allExtensionNumbersResponse(payload as! ExtensionNumberResponse)
            case .listServicesResponse:
                return .listServicesResponse(payload as! ListServiceResponse)
            case .errorResponse:
                return .errorResponse(payload as! ErrorResponse)
            }
        }
        
        var getCodingKeyAndPayload: (CodingKeys, Any?) {
            switch self {
            case .fileDescriptorResponse(let value):
                return (.fileDescriptorResponse, value)
            case .allExtensionNumbersResponse(let value):
                return (.allExtensionNumbersResponse, value)
            case .listServicesResponse(let value):
                return (.listServicesResponse, value)
            case .errorResponse(let value):
                return (.errorResponse, value)
            }
        }
    }
    let validHost: String
    let originalRequest: ReflectionRequest
    let messageResponse: MessageResponse
    
    enum CodingKeys: Int, CodingKey {
        case validHost = 1
        case originalRequest = 2
        case messageResponse = -1 // TODO???!!!!!!
    }
}
