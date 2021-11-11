import Foundation
import ApodiniUtils
@_implementationOnly import Runtime


public protocol AnyProtobufEnumWithAssociatedValues: AnyProtobufTypeWithCustomFieldMapping {
    //init(fromProtobufDecoder decoder: Decoder) throws // TODO would this allow us to circumvent the Codable stuff? (not really bc the enum type would still need to conform to Codable in order to be able to be put in a Codable type...)
    //func encode(toProtobufEncoder encoder: Encoder) throws
}

// TODO update this to use the "PRotobufferTypeWithCustomFieldMapping" protocol? That'd also give us the ability to get the field numbers from the type...
public protocol ProtobufEnumWithAssociatedValues: AnyProtobufEnumWithAssociatedValues, Codable, _ProtobufEmbeddedType, ProtobufTypeWithCustomFieldMapping {
    //associatedtype CodingKeys: Swift.CodingKey & RawRepresentable & CaseIterable where CodingKeys.RawValue == Int
    
    static func makeEnumCase(forCodingKey codingKey: CodingKeys, payload: Any?) -> Self
    var getCodingKeyAndPayload: (CodingKeys, Any?) { get }
//    func encodeCodingKeyAndPayload(to encoder: Encoder) throws
}


extension ProtobufEnumWithAssociatedValues {
    public init(from decoder: Decoder) throws { // TODO this will only work with the _ProtobufferDecoder!!!!!!
        precondition(decoder is _ProtobufferDecoder)
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        let CodingKeysTI = try typeInfo(of: CodingKeys.self)
        precondition(CodingKeysTI.kind == .enum)
        let SelfTI = try typeInfo(of: Self.self)
        precondition(SelfTI.kind == .enum)
        let fieldNumbersByCaseName: [String: Int] = .init(uniqueKeysWithValues: CodingKeys.allCases.map { ($0.stringValue, $0.rawValue) })
        for enumCaseTI in CodingKeysTI.cases {
            let tagValue = fieldNumbersByCaseName[enumCaseTI.name]!
            let enumCase = CodingKeys(intValue: tagValue)!
            if keyedContainer.contains(enumCase) {
                let selfCaseIdx = SelfTI.cases.firstIndex { $0.name == enumCaseTI.name }!
                let selfCaseTI = SelfTI.cases[selfCaseIdx]//.first(where: { $0.name == enumCaseTI.name })!
                let payloadTy = selfCaseTI.payloadType!
                guard let payloadDecodableTy = payloadTy as? Decodable.Type else {
                    fatalError("Enum payload must be Decodable")
                }
                let payloadValue = try keyedContainer.decode(payloadDecodableTy, forKey: enumCase)
                self = Self.makeEnumCase(forCodingKey: enumCase, payload: payloadValue)
                return
            }
        }
        fatalError()
    }
    
    
    public func encode(to encoder: Encoder) throws {
        precondition(encoder is _ProtobufferEncoder)
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
    }
    
    
    var getCodingKeyAndPayload2: (CodingKeys, Any?) {
        let selfMirror = Mirror(reflecting: self)
        let (caseName, payload) = selfMirror.children.first!
        let codingKey = Self.CodingKeys.allCases.first { $0.stringValue == caseName }!
        return (codingKey, isNil(payload) ? nil : payload)
    }
}




