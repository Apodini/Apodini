import Foundation
import ApodiniUtils
@_implementationOnly import Runtime


public protocol LKAnyProtobufferEnumWithAssociatedValues: LKAnyProtobufferCodableWithCustomFieldMapping {}

// TODO update this to use the "PRotobufferTypeWithCustomFieldMapping" protocol? That'd also give us the ability to get the field numbers from the type...
public protocol LKProtobufferEnumWithAssociatedValues: LKAnyProtobufferEnumWithAssociatedValues, Codable, LKProtobufferEmbeddedOneofType, LKProtobufferCodableWithCustomFieldMapping {
    //associatedtype CodingKeys: Swift.CodingKey & RawRepresentable & CaseIterable where CodingKeys.RawValue == Int
    
    static func makeEnumCase(forCodingKey codingKey: CodingKeys, payload: Any?) -> Self
    var getCodingKeyAndPayload: (CodingKeys, Any?) { get }
//    func encodeCodingKeyAndPayload(to encoder: Encoder) throws
}


extension LKProtobufferEnumWithAssociatedValues {
    public init(from decoder: Decoder) throws { // TODO this will only work with the LKProtobufferDecoder!!!!!!
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
    
    
    public func encode(to encoder: Encoder) throws {
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




