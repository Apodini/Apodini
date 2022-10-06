//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Runtime
import ApodiniUtils
import Foundation
import NIOHPACK
import ProtobufferCoding


// MARK: RPC Handler

class ServerReflectionInfoRPCHandler: GRPCStreamRPCHandler {
    private unowned let server: GRPCServer
    
    init(server: GRPCServer) {
        self.server = server
    }
    
    func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut> {
        let reflectionRequest: ReflectionRequest
        do {
            reflectionRequest = try ProtobufferDecoder().decode(ReflectionRequest.self, from: message.payload)
        } catch {
            return context.eventLoop.makeFailedFuture(GRPCStatus(code: .internal, message: "Unable to decode reflection request"))
        }
        let reflectionResponse: ReflectionResponse
        switch reflectionRequest.messageRequest {
        case .fileByFilename(let filename):
            guard let fileDescriptor = server.fileDescriptor(forFilename: filename) else {
                return context.eventLoop.makeFailedFuture(GRPCStatus(code: .internal, message: "Unable to find file '\(filename)'"))
            }
            reflectionResponse = ReflectionResponse(
                validHost: reflectionRequest.host,
                originalRequest: reflectionRequest,
                messageResponse: .fileDescriptorResponse(FileDescriptorResponse(fileDescriptors: [fileDescriptor]))
            )
        case .fileContainingSymbol(let symbol):
            guard let fileDescriptor = server.fileDescriptor(forSymbol: symbol) else {
                return context.eventLoop.makeFailedFuture(GRPCStatus(code: .internal, message: "Unable to find symbol '\(symbol)'"))
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
                    errorCode: Int32(GRPCStatus.Code.unimplemented.rawValue),
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
    
    
    static func registerReflectionServiceTypesWithSchema(
        _ schema: ProtoSchema
    ) throws -> (inputType: ProtoType, outputType: ProtoType) {
        let input = try schema.informAboutMessageType(ReflectionRequest.self)
        let output = try schema.informAboutMessageType(ReflectionResponse.self)
        return (input, output)
    }
}


// MARK: Server Reflection Support

extension GRPCServer {
    fileprivate func handleMakeFileContainingSymbolRequest(
        _ reflectionRequest: ReflectionRequest,
        forSymbol symbolName: String
    ) throws -> ReflectionResponse? {
        // Proto docs: (https://github.com/grpc/grpc/blob/master/src/proto/grpc/reflection/v1alpha/reflection.proto)
        //      Find the proto file that declares the given fully-qualified symbol name.
        //      This field should be a fully-qualified symbol name
        //      (e.g. <package>.<service>[.<method>] or <package>.<type>).
        // The main issue here is deconstructing the symbol into a service (and method) name. There's also that type thing???
        
        // Normally, this would look need to loop up the file containing the requested symbol.
        // Thing is, however, we don't actually have any files, so we instead just check whether
        // the symbol is known to the server, and, if it is, return the server's whole proto definition.
        if let fileDescriptor = fileDescriptor(forSymbol: symbolName) {
            return ReflectionResponse(
                validHost: reflectionRequest.host,
                originalRequest: reflectionRequest,
                messageResponse: .fileDescriptorResponse(.init(fileDescriptors: [fileDescriptor]))
            )
        } else {
            return nil
        }
    }
    
    
    fileprivate func handleListServicesReflectionRequest(_ reflectionRequest: ReflectionRequest) -> ReflectionResponse {
        ReflectionResponse(
            validHost: reflectionRequest.host,
            originalRequest: reflectionRequest,
            messageResponse: .listServicesResponse(ListServiceResponse(
                services: services.map { ServiceResponse(name: "\($0.packageName).\($0.name)") }
            ))
        )
    }
}


// MARK: Reflection Service Types

protocol __ProtoNS_GRPC_Reflection_V1Alpha: ProtoTypeInPackage {}
extension __ProtoNS_GRPC_Reflection_V1Alpha {
    static var package: ProtobufPackageUnit {
        ProtobufPackageUnit(
            packageName: "grpc.reflection.v1alpha",
            filename: "grpc/reflection/v1alpha/reflection.proto"
        )
    }
}


struct ExtensionRequest: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let containingType: String
    let extensionNumber: Int32
    enum CodingKeys: Int, CodingKey {
        case containingType = 1
        case extensionNumber = 2
    }
}


struct ReflectionRequest: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha, ProtoTypeWithCustomProtoName {
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
    }
    
    let host: String
    let messageRequest: MessageRequest
    
    enum CodingKeys: Int, CodingKey {
        case host = 1
        case messageRequest = -1
    }
}


// MARK: ReflectionResponse

struct FileDescriptorResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let fileDescriptors: [FileDescriptorProto]
    
    enum CodingKeys: Int, CodingKey {
        case fileDescriptors = 1
    }
}


struct ExtensionNumberResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let baseTypeName: String
    let extensionNumber: [Int32]
    
    enum CodingKeys: Int, CodingKey {
        case baseTypeName = 1
        case extensionNumber = 2
    }
}


struct ListServiceResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let services: [ServiceResponse]
    
    enum CodingKeys: Int, CodingKey {
        case services = 1
    }
}


struct ServiceResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let name: String
    
    enum CodingKeys: Int, CodingKey {
        case name = 1
    }
}


struct ErrorResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha {
    let errorCode: Int32
    let errorMessage: String
    
    enum CodingKeys: Int, CodingKey {
        case errorCode = 1
        case errorMessage = 2
    }
}

struct ReflectionResponse: Codable, ProtobufMessage, Equatable, __ProtoNS_GRPC_Reflection_V1Alpha, ProtoTypeWithCustomProtoName {
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
    }
    let validHost: String
    let originalRequest: ReflectionRequest
    let messageResponse: MessageResponse
    
    enum CodingKeys: Int, CodingKey {
        case validHost = 1
        case originalRequest = 2
        case messageResponse = -1
    }
}
