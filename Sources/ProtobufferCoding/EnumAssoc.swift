//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniUtils
@_implementationOnly import Runtime


/// Type-erased version of `ProtobufEnumWithAssociatedValues`
public protocol AnyProtobufEnumWithAssociatedValues: AnyProtobufTypeWithCustomFieldMapping {}


/// A protobuffer-coding-compatible enum with associated values.
/// - Note: You can use this to model a `oneof` type in your proto schema.
public protocol ProtobufEnumWithAssociatedValues: AnyProtobufEnumWithAssociatedValues, Codable,
                                                  _ProtobufEmbeddedType, ProtobufTypeWithCustomFieldMapping {
    static func makeEnumCase(forCodingKey codingKey: CodingKeys, payload: Any?) -> Self
}


extension Encodable {
    fileprivate func _encode<Key: CodingKey>(into container: inout KeyedEncodingContainer<Key>, forKey key: Key) throws {
        try container.encode(self, forKey: key)
    }
}

extension ProtobufEnumWithAssociatedValues {
    /// Default `Decodable` implementation, decoding this enum type from a protobuf value
    /// - NOTE: This will only work with the `_ProtobufferDecoder`
    public init(from decoder: any Decoder) throws {
        precondition(decoder is _ProtobufferDecoder)
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        let codingKeysTI = try typeInfo(of: CodingKeys.self)
        precondition(codingKeysTI.kind == .enum)
        let selfTI = try typeInfo(of: Self.self)
        precondition(selfTI.kind == .enum)
        let fieldNumbersByCaseName: [String: Int] = .init(uniqueKeysWithValues: CodingKeys.allCases.map { ($0.stringValue, $0.rawValue) })
        for enumCaseTI in codingKeysTI.cases {
            let tagValue = fieldNumbersByCaseName[enumCaseTI.name]!
            let enumCase = CodingKeys(intValue: tagValue)!
            if keyedContainer.contains(enumCase) {
                let selfCaseIdx = selfTI.cases.firstIndex { $0.name == enumCaseTI.name }!
                let selfCaseTI = selfTI.cases[selfCaseIdx]//.first(where: { $0.name == enumCaseTI.name })!
                let payloadTy = selfCaseTI.payloadType!
                guard let payloadDecodableTy = payloadTy as? any Decodable.Type else {
                    fatalError("Enum payload must be Decodable")
                }
                let payloadValue = try keyedContainer.decode(payloadDecodableTy, forKey: enumCase)
                self = Self.makeEnumCase(forCodingKey: enumCase, payload: payloadValue)
                return
            }
        }
        fatalError("Unable to decode enum type \(Self.self) from \(decoder)")
    }
    
    
    /// Default `Encodable` implementation, encoding this enum type to a protobuf value
    /// - NOTE: This will only work with the `_ProtobufferEncoder`
    public func encode(to encoder: any Encoder) throws {
        precondition(encoder is _ProtobufferEncoder)
        let (codingKey, payload) = self.getCodingKeyAndPayload
        var keyedEncodingContainer = encoder.container(keyedBy: CodingKeys.self)
        guard let payload = payload as? any Encodable else {
            fatalError("Payload of type \(type(of: payload)) is not Encodable.")
        }
        try payload._encode(into: &keyedEncodingContainer, forKey: codingKey)
    }
    
    
    var getCodingKeyAndPayload: (CodingKeys, Any?) {
        let selfMirror = Mirror(reflecting: self)
        let (caseName, payload) = selfMirror.children.first!
        let codingKey = Self.CodingKeys.allCases.first { $0.stringValue == caseName }!
        return (codingKey, isNil(payload) ? nil : payload)
    }
}
