import Apodini
import ProtobufferCoding
import Runtime
import ApodiniUtils
import Foundation
import NIOHPACK
import AssociatedTypeRequirementsVisitor


////struct ServerReflectionInfoHandler: Handler {
////    func handle() async throws -> [] {
////        <#code#>
////    }
////}
//
////
////
////extension ServerReflectionInfoHandler {
////    struct Input {
////
////    }
////
////    struct Output {
////        let valid_host: String
////        let original_request: Input
////    }
////}
//
//
//public struct ReflectionRequest: Codable {
//
//}
//
//
//public struct ReflectionResponse: Codable {
//    let valid_host: String
//    let original_request: ReflectionRequest
//}
//
//
//internal struct GRPCReflectionHandlerImp: Handler {
//    @Parameter
//    var host: String
//
//    public func handle() async throws -> [ReflectionResponse] {
//        print(Self.self, #function, self)
//        print(host)
//        fatalError()
//    }
//}
//
//
//public struct GRPCReflection: Component {
//    public init() {}
//
//    public var content: some Component {
//        GRPCReflectionHandlerImp()
//            //.gRPCv2ServiceName(GRPCv2InterfaceExporter.serverReflectionServiceName)
//            //.gRPCv2MethodName(GRPCv2InterfaceExporter.serverReflectionMethodName)
//    }
//}


protocol LKAnyProtobufferEnumWithAssociatedValues: LKAnyProtobufferCodableWithCustomFieldMapping {}

// TODO update this to use the "PRotobufferTypeWithCustomFieldMapping" protocol? That'd also give us the ability to get the field numbers from the type...
protocol LKProtobufferEnumWithAssociatedValues: LKAnyProtobufferEnumWithAssociatedValues, Codable, LKProtobufferEmbeddedOneofType, LKProtobufferCodableWithCustomFieldMapping {
    //associatedtype CodingKeys: Swift.CodingKey & RawRepresentable & CaseIterable where CodingKeys.RawValue == Int
    
    static func makeEnumCase(forCodingKey codingKey: CodingKeys, payload: Any?) -> Self
    var getCodingKeyAndPayload: (CodingKeys, Any?) { get }
//    func encodeCodingKeyAndPayload(to encoder: Encoder) throws
}


extension LKProtobufferEnumWithAssociatedValues {
    init(from decoder: Decoder) throws { // TODO this will only work with the LKProtobufferDecoder!!!!!!
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        let CodingKeysTI = try typeInfo(of: CodingKeys.self)
        precondition(CodingKeysTI.kind == .enum)
        let SelfTI = try typeInfo(of: Self.self)
        precondition(SelfTI.kind == .enum)
        let fieldNumbersByCaseName: [String: Int] = .init(uniqueKeysWithValues: CodingKeys.allCases.map { ($0.stringValue, $0.rawValue) })
        for enumCaseTI in CodingKeysTI.cases {
            let tagValue = fieldNumbersByCaseName[enumCaseTI.name]!
            let enumCase = CodingKeys(intValue: tagValue)!
//            print(tagValue, enumCaseTI, keyedContainer.contains(enumCase))
            if keyedContainer.contains(enumCase) {
                let selfCaseIdx = SelfTI.cases.firstIndex { $0.name == enumCaseTI.name }!
                let selfCaseTI = SelfTI.cases[selfCaseIdx]//.first(where: { $0.name == enumCaseTI.name })!
                let payloadTy = selfCaseTI.payloadType!
//                print(payloadTy, payloadTy as? Decodable.Type, type(of: payloadTy as! Decodable.Type) as? Decodable.Protocol)
                guard let payloadDecodableTy = payloadTy as? Decodable.Type else {
                    fatalError("Enum payload must be Decodable")
                }
//                print(payloadTy, LKGetTypeMemoryLayoutSize(payloadTy))
//                print(Decodable.self, MemoryLayout<Decodable>.size)
//                print(Decodable.Type.self, MemoryLayout<Decodable.Type>.size)
//                print(Decodable.Protocol.self, MemoryLayout<Decodable.Protocol>.size)
//                if let rawBytesSupportingKeyedContainer = keyedContainer as? LKRawBytesSupportingKeyedDecodingContainer {
////                    let buffer = try rawDataSupportingKeyedContainer.getRawBytes(forKey: enumCase)
////                    let decoder = _LKProtobufferDecoder(codingPath: rawBytesSupportingKeyedContainer, userInfo: <#T##[CodingUserInfoKey : Any]#>, buffer: <#T##ByteBuffer#>)
////                    let payloadValue = (payloadTy as! Decodable.Type)
//                    let payloadValue = try rawBytesSupportingKeyedContainer.decode(payloadDecodableTy, forKey: enumCase)
//                    print("PAYLOAD VALUE", payloadValue)
//                }
//                fuckingHellThisIsSoBad.currentValue!.value = payloadDecodableTy
//                let decodingInfo = try keyedContainer.decode(LKDecodeTypeErasedDecodableTypeHelper.self, forKey: enumCase)
//                print(decodingInfo)
                //keyedContainer.decode(<#T##type: Decodable.Protocol##Decodable.Protocol#>, forKey: <#T##CaseIterable & CodingKey & RawRepresentable#>)
                //let payloadValue = try keyedContainer.decode(payloadDecodableTy, forKey: enumCase)
                //print(enumCase, payloadValue)
                let payloadValue = try keyedContainer.decode(payloadDecodableTy, forKey: enumCase)
                //print("PAYLOAD VALUE", payloadValue)
//                print("Self.size", MemoryLayout<Self>.size)
                self = Self.makeEnumCase(forCodingKey: enumCase, payload: payloadValue)
                return
            }
        }
//        for enumCase in CodingKeys.allCases {
//            //let tag = enumCase.rawValue
//            print(enumCase, enumCase.rawValue, enumCase.stringValue, enumCase.intValue)
//            let tag = enumCase.rawValue
//        }
        fatalError()
    }
    
    
    func encode(to encoder: Encoder) throws {
        precondition(encoder is _LKProtobufferEncoder)
//        // TODO somehow get the current coding key and payload dynamically!
//        let TI1 = try typeInfo(of: type(of: self))
//        let TI2 = try typeInfo(of: Self.self)
//        print(TI1)
//        print(TI2)
        let (codingKey, payload) = self.getCodingKeyAndPayload
        let _0 = String(describing: self.getCodingKeyAndPayload)
        let _1 = String(describing: self.getCodingKeyAndPayload2)
        precondition(_0 == _1, "\(_0) != \(_1)")

        //var singleValueContainer = encoder.singleValueContainer()
        //try singleValueContainer.encode(try _LKAlreadyEncodedProtoField(fieldNumber: codingKey.intValue!, value: payload as! Encodable))
        
        var keyedEncodingContainer = encoder.container(keyedBy: CodingKeys.self)
        let containerContainer = _KeyedEncodingContainerContainer<CodingKeys>.init(key: codingKey, keyedEncodingContainer: keyedEncodingContainer)
        let encodableATRVisitor = AnyEncodableEncodeIntoKeyedEncodingContainerATRVisitor(containerContainer: containerContainer)
        switch encodableATRVisitor(payload as! Encodable) {
        case nil:
            fatalError("Nil")
        case .failure(let error):
            fatalError("Error: \(error)")
        case .success:
            //fatalError("Success")
            break
        }
        keyedEncodingContainer = containerContainer.keyedEncodingContainer

//        let FE = FakeEncoder()
//        FE.testWithGenerics(payload as! Encodable)
//        FE.testWithoutGenerics(payload as! Encodable)
//        keyedContainer.encode(payload as! Encodable, forKey: codingKey)
//        let encodableATRVisitor = AnyEncodableEncodeIntoKeyedEncodingContainerATRVisitor(containerBox: Box(keyedContainer), key: codingKey)
//        switch encodableATRVisitor(payload as! Encodable) {
//        case nil:
//            fatalError("Nil result")
//        case .failure(let error):
//            fatalError("Error: \(error)")
//        case .success:
//            fatalError("Success")
//        }
//        keyedContainer = encodableATRVisitor.containerBox.value
//        try encodeCodingKeyAndPayload(to: encoder) // TODO get rid of this and use the code above instead!
    }
    
    
    var getCodingKeyAndPayload2: (CodingKeys, Any?) {
        let selfMirror = Mirror(reflecting: self)
        let (caseName, payload) = selfMirror.children.first!
        let codingKey = Self.CodingKeys.allCases.first { $0.stringValue == caseName }!
        return (codingKey, isNil(payload) ? nil : payload)
    }
}



//protocol LKIgnoreInReflection_REF: LKIgnoreInReflection {}
//protocol LKIgnoreInReflection_REF: LKIgnoreInReflection, __ProtoNS_GRPC_Reflection_V1Alpha {}
protocol LKIgnoreInReflection_REF: __ProtoNS_GRPC_Reflection_V1Alpha {}

struct FakeEncoder {
    func testWithGenerics<T: Encodable>(_ value: T) {}
    func testWithoutGenerics(_ value: Encodable) {}
}


private struct ExtensionRequest: Codable, LKProtobufferMessage, Equatable, LKIgnoreInReflection_REF {
    let containingType: String
    let extensionNumber: Int32
    enum CodingKeys: Int, CodingKey {
        case containingType = 1
        case extensionNumber = 2
    }
}


private struct ReflectionRequest: Codable, LKProtobufferMessage, Equatable, LKIgnoreInReflection_REF, __Proto_TypeWithCustomProtoName {
    static var protoTypeName: String { "ServerReflectionRequest" }
    
    enum MessageRequest: LKProtobufferEnumWithAssociatedValues, Equatable, LKIgnoreInReflection_REF {
        case fileByFilename(String)
        case fileContainingSymbol(String)
        case fileContainingExtension(ExtensionRequest)
        case allExtensionNumbersOfType(String)
        case listServices(String)
        
        enum CodingKeys: Int, CodingKey, CaseIterable, LKProtobufferMessageCodingKeys {
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


private struct FileDescriptorResponse: Codable, LKProtobufferMessage, Equatable, LKIgnoreInReflection_REF {
    //let rawBytes: [[UInt8]] // TODO this is another serialised message?????
    //let rawBytes: [FieldDescriptorProto] // TODO we can use thie directly!
    let fileDescriptors: [FileDescriptorProto]
    
    enum CodingKeys: Int, CodingKey {
        case fileDescriptors = 1
    }
}


private struct ExtensionNumberResponse: Codable, LKProtobufferMessage, Equatable, LKIgnoreInReflection_REF {
    let baseTypeName: String
    let extensionNumber: [Int32]
    
    enum CodingKeys: Int, CodingKey {
        case baseTypeName = 1
        case extensionNumber = 2
    }
}


private struct ListServiceResponse: Codable, LKProtobufferMessage, Equatable, LKIgnoreInReflection_REF {
    let services: [ServiceResponse]
    
    enum CodingKeys: Int, CodingKey {
        case services = 1
    }
}


private struct ServiceResponse: Codable, LKProtobufferMessage, Equatable, LKIgnoreInReflection_REF {
    let name: String
    
    enum CodingKeys: Int, CodingKey {
        case name = 1
    }
}


private struct ErrorResponse: Codable, LKProtobufferMessage, Equatable, LKIgnoreInReflection_REF {
    let errorCode: Int32
    let errorMessage: String
    
    enum CodingKeys: Int, CodingKey {
        case errorCode = 1
        case errorMessage = 2
    }
}


func TODO_REMOVE_getReflectionAPIRelatedProtoTypess() -> [Any.Type] {
    [ReflectionResponse.self] // TODO return also the request type and check whether the type handling thing properly uses the cached result...
}

private struct ReflectionResponse: Codable, LKProtobufferMessage, Equatable, LKIgnoreInReflection_REF, __Proto_TypeWithCustomProtoName {
    static var protoTypeName: String { "ServerReflectionResponse" }
    
    enum MessageResponse: LKProtobufferEnumWithAssociatedValues, Equatable, LKIgnoreInReflection_REF {
        case fileDescriptorResponse(FileDescriptorResponse)
        case allExtensionNumbersResponse(ExtensionNumberResponse)
        case listServicesResponse(ListServiceResponse)
        case errorResponse(ErrorResponse)
        
        enum CodingKeys: Int, CodingKey, CaseIterable, LKProtobufferMessageCodingKeys {
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



//protocol LKProtoMessageProotocolNEW {
//    associatedtype CodingKeys: RawRepresentable & CodingKey & CaseIterable where Self.CodingKeys.RawValue == Int
//}


enum TestEnum: LKProtobufferEnumWithAssociatedValues, Equatable {
    case int(Int)
    case float(Float)
    case double(Double)
    case string(String)

    enum CodingKeys: Int, CodingKey, CaseIterable, LKProtobufferMessageCodingKeys {
        case int = 1
        case float = 2
        case double = 3
        case string = 4
    }

    static func makeEnumCase(forCodingKey codingKey: CodingKeys, payload: Any?) -> TestEnum {
        switch codingKey {
        case .int:
            //print(type(of: payload), payload)
            //fatalError()
            return .int(payload as! Int)
        case .float:
            return .float(payload as! Float)
        case .double:
            return .double(payload as! Double)
        case .string:
            return .string(payload as! String)
        }
    }

    var getCodingKeyAndPayload: (CodingKeys, Any?) {
        switch self {
        case .int(let value):
            return (.int, value)
        case .float(let value):
            return (.float, value)
        case .double(let value):
            return (.double, value)
        case .string(let value):
            return (.string, value)
        }
    }
}



struct TestPerson: Codable, Equatable, LKProtobufferMessage {
    let age: Int
    let names: [String]
    
    enum CodingKeys: Int, CodingKey {
        case age = 1
        case names = 2
    }
}


struct TestStruct: Codable, Equatable, LKProtobufferMessage {
    let person: TestPerson
    let number: Int
    
    enum CodingKeys: Int, CodingKey {
        case person = 1
        case number = 2
    }
}



class ServerReflectionInfoRPCHandler: GRPCv2StreamRPCHandler {
    private unowned let server: GRPCv2Server
    
    init(server: GRPCv2Server) {
        self.server = server
    }
    
    func handleStreamOpen(context: GRPCv2StreamConnectionContext) {
        // ...
        print("-[\(Self.self) \(#function)]")
//        let inputs: [TestEnum] = [
//            .int(12), .float(1.2), .double(3.7), .string("Servus")
//        ]
//        for input in inputs {
//            let buf = try! LKProtobufferEncoder().encode(input)
//            print(input, (buf.readerIndex, buf.writerIndex), buf.getBytes(at: 0, length: buf.writerIndex)!)
//            let val = try! LKProtobufferDecoder().decode(TestEnum.self, from: buf)
//            print(input, val)
//            precondition(input == val)
//        }
//        fatalError()
        
//        let input1 = TestStruct(person: TestPerson(age: 23, names: ["AAAAA", "BBBBB"]), number: 52)
//        let encoded = try! LKProtobufferEncoder().encode(input1)
//        print(encoded.lk_getAllBytes())
//        let decoded = try! LKProtobufferDecoder().decode(TestStruct.self, from: encoded)
//        print(decoded)
//        precondition(input1 == decoded)
//        fatalError()
    }
    
    func handleStreamClose(context: GRPCv2StreamConnectionContext) {
        // ...
        print("-[\(Self.self) \(#function)]")
    }
    
    func handle(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut> {
        print(Self.self, #function, message.serviceAndMethodName)
        
//        let bytes: [UInt8] = message.payload.getBytes(at: 0, length: message.payload.readableBytes)!
//        print(bytes.map { String($0, radix: 16, uppercase: false) })
//        print(bytes.map { String($0, radix: 2, uppercase: false) })
//        print(message.payload.getString(at: 0, length: message.payload.readableBytes)!)
        
//        let decoder = ProtobufMessageDecoder(buffer: message.payload)
//        decoder.debugPrintFieldsInfo()
        try! ProtobufMessageLayoutDecoder.getFields(in: message.payload).debugPrintFieldsInfo()
        
        
        let reflectionRequest: ReflectionRequest
        do {
            //let data = message.payload.getAllData()!
            //request = try ProtobufferDecoder().decode(ReflectionRequest.self, from: data)
            reflectionRequest = try LKProtobufferDecoder().decode(ReflectionRequest.self, from: message.payload)
        } catch {
            fatalError("\(error)")
        }
        
        var messageOut = GRPCv2MessageOut(headers: HPACKHeaders(), payload: ByteBuffer(), shouldCloseStream: false)
        messageOut.headers[.contentType] = .gRPC(.proto)
        
        print("reflection request: \(reflectionRequest)")
        
        let _reflectionResponse: ReflectionResponse
        
        do {
            switch reflectionRequest.messageRequest {
            case .fileByFilename(let filename):
                //guard let fileDescriptor = server.fileDescriptors.first(where: { $0.fileDescriptor.name == filename }) else {
                guard let fileDescriptor = server.fileDescriptor(forFilename: filename) else {
                    fatalError()
                }
                let response = ReflectionResponse(
                    validHost: reflectionRequest.host,
                    originalRequest: reflectionRequest,
                    messageResponse: .fileDescriptorResponse(FileDescriptorResponse(fileDescriptors: [fileDescriptor]))
                )
                _reflectionResponse = response
                try LKProtobufferEncoder().encode(response, into: &messageOut.payload)
            case .fileContainingSymbol(let symbol):
                print("FILE CONTAINING SYMBOL", symbol)
                guard let fileDescriptor = server.fileDescriptor(forSymbol: symbol) else {
                    fatalError()
                }
                print("RETURNING", fileDescriptor)
                let response = ReflectionResponse(
                    validHost: reflectionRequest.host,
                    originalRequest: reflectionRequest,
                    messageResponse: .fileDescriptorResponse(FileDescriptorResponse(fileDescriptors: [fileDescriptor]))
                )
                _reflectionResponse = response
                try LKProtobufferEncoder().encode(response, into: &messageOut.payload)
//                var messageOut = GRPCv2MessageOut(
//                    headers: HPACKHeaders {
//                        // TODO what do we want here?
//                        $0[.gRPCEncoding] = nil
//                    },
//                    payload: ByteBufferAllocator().buffer(capacity: 0), // TODO figure out what the expected size of the payload is beforehand!
//                    shouldCloseStream: false
//                )
//                let protoFileDescriptor = try! server.makeFileContainingSymbol(symbol)
//                let encodedProtoFileDescriptor = try! LKProtobufferEncoder().encode(protoFileDescriptor)
//                let response = ReflectionResponse(
//                    validHost: "", // TODO!!! what to put here?
//                    originalRequest: reflectionRequest,
//                    messageResponse: .fileDescriptorResponse(FileDescriptorResponse(
//                        rawBytes: encodedProtoFileDescriptor.getBytes(at: 0, length: encodedProtoFileDescriptor.readableBytes)!
//                    ))
//                )
//                try! LKProtobufferEncoder().encode(response, into: &messageOut.payload)
//                return context.eventLoop.makeSucceededFuture(messageOut)
//                fatalError(".fileContainingSymbol(\(symbol))")
                //guard let response = try server.handleMakeFileContainingSymbolRequest(reflectionRequest, forSymbol: symbol) else {
                //    fatalError()
                //}
                //_reflectionResponse = response
                //try LKProtobufferEncoder().encode(response, into: &messageOut.payload)
            case .fileContainingExtension(let extensionRequest):
                fatalError(".fileContainingExtension(\(extensionRequest))")
            case .allExtensionNumbersOfType(let strVal): // TODO name!
                fatalError(".allExtensionNumbersOfType(\(strVal))")
            case .listServices(let inputStr):
                let response = server.handleListServicesReflectionRequest(reflectionRequest)
                _reflectionResponse = response
                try LKProtobufferEncoder().encode(response, into: &messageOut.payload)
            }
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }
        
        let data = messageOut.payload.getData(at: 0, length: messageOut.payload.writerIndex)!
        try! data.write(to: URL(fileURLWithPath: "/Users/lukas/temp/ApodiniRawProtoOut"))
        
        let decodedResponse = try! LKProtobufferDecoder().decode(ReflectionResponse.self, from: messageOut.payload)
//        print("validHost", decodedResponse.validHost == _reflectionResponse.validHost)
//        print("origRequest", decodedResponse.originalRequest == _reflectionResponse.originalRequest)
//        print("messageResponse", decodedResponse.messageResponse == _reflectionResponse.messageResponse)
//        print("A", _reflectionResponse.messageResponse)
        //print("B", decodedResponse.messageResponse)
        //print("decodedResponse: \(decodedResponse), \(decodedResponse == _reflectionResponse)")
//        debugPrint("ORIG", _reflectionResponse)
//        debugPrint("DECO", decodedResponse)
        precondition(decodedResponse == _reflectionResponse)
//        fatalError()
        return context.eventLoop.makeSucceededFuture(messageOut)
    }
}





// MARK: Server Reflection Support

extension GRPCv2Server {
    fileprivate func handleMakeFileContainingSymbolRequest(_ reflectionRequest: ReflectionRequest, forSymbol symbolName: String) throws -> ReflectionResponse? {
        // TODO cache the results here?!!!!
        
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
//            if let _ = service(named: symbolName) {
//                return true
//            }
            return false
        }()
        
        guard isKnownSymbol else {
            return nil
        }
        
        //DescriptorProto(name: <#T##String?#>, fields: <#T##[FieldDescriptorProto]#>, extensions: <#T##[FieldDescriptorProto]#>, nestedTypes: <#T##[DescriptorProto]#>, enumTypes: <#T##[EnumDescriptorProto]#>, extensionRanges: <#T##[DescriptorProto.ExtensionRange]#>, oneofDecls: <#T##[OneofDescriptorProto]#>, options: <#T##MessageOptions?#>, reservedRanges: <#T##[DescriptorProto.ReservedRange]#>, reservedNames: <#T##[String]#>)
        
        //let typeDescriptors = GRPCv2ProtoSchemaTypeProducer.run()
        
//        // Descriptor of the main services (i.e. the ones defined in the web service)
//        let mainServicseDescriptorProto = FileDescriptorProto(
//            name: "__filename__",
//            package: self.packageName,
//            dependencies: [
//                "reflection.proto"
//            ],
//            publicDependency: [],
//            weakDependency: [],
//            //messageTypes: [], // <#T##[DescriptorProto]#>,
//            //messageTypes: schema.finalisedTopLevelMessageTypes.sorted(by: \.name),
//            messageTypes: schema.messageTypeDescriptors(forPackage: self.packageName),
//            //enumTypes: [], // <#T##[EnumDescriptorProto]#>,
//            //enumTypes: self.schema.finalisedTopLevelEnumTypes.sorted(by: \.name),
//            enumTypes: self.schema.enumTypeDescriptors(forPackage: self.packageName),
//            services: self.services.compactMap { service -> ServiceDescriptorProto? in
//                guard service.name != GRPCv2InterfaceExporter.serverReflectionServiceName else {
//                    return nil
//                }
//                return ServiceDescriptorProto(
//                    name: service.name,
//                    methods: service.methods.map { method -> MethodDescriptorProto in
//                        MethodDescriptorProto(
//                            name: method.name,
//                            inputType: nil,  // TODO
//                            outputType: nil, // TODO
//                            options: nil, // TODO use this to mark methods as deprecated? Can we currently express that in Apodini? Maybe add a modifier?
//                            clientStreaming: method.type == .clientStreaming || method.type == .bidirectional,
//                            serverStreaming: method.type == .serviceStreaming || method.type == .bidirectional
//                        )
//                    },
//                    options: nil // TODO use this to deprecate services? Add an option via a modifier?
//                )
//            },
//            extensions: [], // <#T##[FieldDescriptorProto]#>,
//            options: nil, // <#T##FileOptions?#>,
//            sourceCodeInfo: nil,
//            syntax: "proto3"
//        )
        
//        let encodedFDRes = try LKProtobufferEncoder().encode([fileDescriptorProto])
//        let decodedFDRes = try LKProtobufferDecoder().decode([FileDescriptorProto].self, from: encodedFDRes)
//        precondition([fileDescriptorProto] == decodedFDRes)
//        let encodedFDResBytes = encodedFDRes.getBytes(at: 0, length: encodedFDRes.readableBytes)!
        
        //let protoDescriptorsDescriptor = makeFileDescriptorProto(forPackage: "google.protobuf", name: "google/protobuf/descriptors.proto", dependencies: [])
        
        let reflectionDescriptor = makeFileDescriptorProto(
            forPackage: GRPCv2InterfaceExporter.serverReflectionPackageName,
            name: "grpc_reflection/v1alpha/reflection.proto"
            //dependencies: ["google/protobuf/descriptor.proto"]
            //dependencies: [protoDescriptorsDescriptor.name]
        )
        
        let fileDescriptorResponse = FileDescriptorResponse(fileDescriptors: [
            //protoDescriptorsDescriptor,
            //reflectionDescriptor,
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
                            clientStreaming: method.type == .clientStreaming || method.type == .bidirectional,
                            serverStreaming: method.type == .serviceStreaming || method.type == .bidirectional
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
    
    
//    func makeReflectionServiceProtoFileDescriptor() -> FileDescriptorProto {
//        let reflectionService = self.service(named: GRPCv2InterfaceExporter.serverReflectionServiceName)!
//        return FileDescriptorProto(
//            name: "reflection.proto",
//            package: "grpc.reflection.v1alpha",
//            dependencies: [
//                "google/protobuf/descriptor.proto"
//            ],
//            publicDependency: [],
//            weakDependency: [],
//            messageTypes: [
//                // TODO
//            ],
//            enumTypes: [
//                // TODO
//            ],
//            services: [
//                ServiceDescriptorProto(
//                    name: reflectionService.name,
//                    methods: reflectionService.methods.map { method -> MethodDescriptorProto in
//                        MethodDescriptorProto(
//                            name: method.name,
//                            inputType: { fatalError() }(),
//                            outputType: { fatalError() }(),
//                            options: nil, // TODO use this to mark methods as deprecated? Can we currently express that in Apodini? Maybe add a modifier?
//                            clientStreaming: method.type == .clientStreaming || method.type == .bidirectional,
//                            serverStreaming: method.type == .serviceStreaming || method.type == .bidirectional
//                        )
//                    },
//                    options: nil
//                )
//            ],
//            extensions: [],
//            options: nil,
//            sourceCodeInfo: nil,
//            syntax: "proto3"
//        )
//    }
    
//    private func _computeListOfMessageAndEnumTypes() -> (messageTypes: [DescriptorProto], enumTypes: [EnumDescriptorProto]) {
//        var messageTypes: [DescriptorProto] = []
//        var enumTypes: Set<EnumDescriptorProto> = []
//
////        for (typename, protoType) in GRPCv2HandlerMessageTypeMapper.shared.allMessageTypes {
////            precondition(typename.hasPrefix("."))
////            let potentialParentTypename: String? = {
//////                let components = typename.split(separator: ".")
//////                if components == 1 {
//////                    return nil
//////                } else {
//////                    return ".\(components.dropLast().joined(separator: "."))"
//////                }
////                getParentTypename(typename)
////            }()
////            if let parentTypename = potentialParentTypename, let parentProtoType = GRPCv2HandlerMessageTypeMapper.shared.allMessageTypes {
////
////            }
////        }
////        return (messageTypes, enumTypes)
//        return GRPCv2ProtoSchemaTypeProducer.run()
//    }
    
    
//    private func getParentTypename(_ typename: String) -> String? {
//        let components = typename.split(separator: ".")
//        if components == 1 {
//            return nil
//        } else {
//            return ".\(components.dropLast().joined(separator: "."))"
//        }
//    }
}





//struct GRPCv2ProtoSchemaTypeProducer {
//    let messageTypesInput: [ProtoTypeDerivedFromSwift]
//    let enumTypesInput: [ProtoTypeDerivedFromSwift]
//    //let oneofTypesInput: [ProtoTypeDerivedFromSwift] // TODO
//
//    private var topLevelMessageTypesOutput: Set<DescriptorProto> = []
//    private var topLevelEnumTypesOutput: Set<EnumDescriptorProto> = []
//
//    private var didRun = false
//
//    private init() {
//        messageTypesInput = Array(GRPCv2HandlerMessageTypeMapper.shared.allMessageTypes.values)
//        enumTypesInput = Array(GRPCv2HandlerMessageTypeMapper.shared.allEnumTypes.values)
//    }
//
//    static func run(on server: GRPCv2Server) -> (topLevelMessageTypes: Set<DescriptorProto>, topLevelEnumTypes: Set<EnumDescriptorProto>) {
//        var instance = Self()
//        return instance.run()
//    }
//}








func LKGetProtoFieldType(_ type: Any.Type) -> FieldDescriptorProto.FieldType {
    if type == Int.self || type == Int64.self { // TODO this will break on a system where Int != Int64
        return .TYPE_INT64
    } else if type == UInt.self || type == UInt64.self {  // TODO this will break on a system where UInt != UInt64
        return .TYPE_UINT64
    } else if type == Int32.self {
        return .TYPE_INT32
    } else if type == UInt32.self {
        return .TYPE_UINT32
    //} else if type == Int16.self || type == UInt16.self // TODO add support for these? and then simply map them to the smallest int where they'd fit. Also add the corresponding logic to the en/decoder!
    } else if type == Bool.self {
        return .TYPE_BOOL
    } else if type == Float.self {
        return .TYPE_FLOAT
    } else if type == Double.self {
        return .TYPE_DOUBLE
    } else if type == String.self {
        return .TYPE_STRING
    } else if type == Array<UInt8>.self || type == Data.self {
        return .TYPE_BYTES
    } else if LKGetProtoCodingKind(type) == .message {
        return .TYPE_MESSAGE
    } else {
        fatalError("Unsupported type '\(type)'")
    }
}



extension Sequence {
    func mapIntoSet<Result: Hashable>(_ transform: (Element) throws -> Result) rethrows -> Set<Result> {
        var retval = Set<Result>()
        retval.reserveCapacity(self.underestimatedCount)
        for element in self {
            retval.insert(try transform(element))
        }
        return retval
    }
    
    
    func count(where predicate: (Element) -> Bool) -> Int {
        var retval = 0
        for element in self {
            if predicate(element) {
                retval += 1
            }
        }
        return retval
    }
}
