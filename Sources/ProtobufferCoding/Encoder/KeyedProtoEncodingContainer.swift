//
//  KeyedProtoEncodingContainer.swift
//
//
//  Created by Moritz Schüll on 27.11.20.
//

import Foundation

class KeyedProtoEncodingContainer<Key: CodingKey>: InternalProtoEncodingContainer, KeyedEncodingContainerProtocol {
    override init(using encoder: InternalProtoEncoder, codingPath: [CodingKey]) {
        super.init(using: encoder, codingPath: codingPath)
    }

    //// Tries to convert the given CodingKey to an Int, using the following steps:
    ///  - extract Int raw value, if possible
    ///  - convert to `ProtobufferCodingKey` and read `protoRawValue` property, if possible
    ///  - call default implementation of `_protoRawValue` for `CodingKey`,
    ///    which simply enumerates all cases of the type
    ///  - throws ProtoError.unknownCodingKey, if none of the above works
    private func convertToProtobufferFieldNumber(_ key: Key) throws -> Int {
        codingPath.append(key)
        if let keyValue = key.intValue {
            return keyValue
        } else if let protoKey = key as? ProtobufferCodingKey {
            return protoKey.protoRawValue
        } else {
            return try key.defaultProtoRawValue()
        }
    }

    func encodeNil(forKey key: Key) throws {
        codingPath.append(key)
        // nothing to do
    }

    func encode(_ value: Bool, forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeBool(value, tag: keyValue)
    }

    func encode(_ value: String, forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeString(value, tag: keyValue)
    }

    func encode(_ value: Double, forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeDouble(value, tag: keyValue)
    }

    func encode(_ value: Float, forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeFloat(value, tag: keyValue)
    }

    func encode(_ value: Int, forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeInt(value, tag: keyValue)
    }

    func encode(_ value: Int8, forKey key: Key) throws {
        throw ProtoError.encodingError("Int8 not supported, use Int32 or Int64")
    }

    func encode(_ value: Int16, forKey key: Key) throws {
        throw ProtoError.encodingError("Int16 not supported, use Int32 or Int64")
    }

    func encode(_ value: Int32, forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeInt32(value, tag: keyValue)
    }

    func encode(_ value: Int64, forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeInt64(value, tag: keyValue)
    }

    func encode(_ value: UInt, forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeUInt(value, tag: keyValue)
    }

    func encode(_ value: UInt8, forKey key: Key) throws {
        throw ProtoError.encodingError("UInt8 not supported, use UInt32 or UInt64")
    }

    func encode(_ value: UInt16, forKey key: Key) throws {
        throw ProtoError.encodingError("UInt16 not supported, use UInt32 or UInt64")
    }

    func encode(_ value: UInt32, forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeUInt32(value, tag: keyValue)
    }

    func encode(_ value: UInt64, forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeUInt64(value, tag: keyValue)
    }

    func encode(_ values: [Bool], forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeRepeatedBool(values, tag: keyValue)
    }

    func encode(_ values: [Double], forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeRepeatedDouble(values, tag: keyValue)
    }

    func encode(_ values: [Float], forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeRepeatedFloat(values, tag: keyValue)
    }

    func encode(_ values: [Int], forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeRepeatedInt(values, tag: keyValue)
    }

    func encode(_ values: [Int32], forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeRepeatedInt32(values, tag: keyValue)
    }

    func encode(_ values: [Int64], forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeRepeatedInt64(values, tag: keyValue)
    }

    func encode(_ values: [UInt], forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeRepeatedUInt(values, tag: keyValue)
    }

    func encode(_ values: [UInt32], forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeRepeatedUInt32(values, tag: keyValue)
    }

    func encode(_ values: [UInt64], forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeRepeatedUInt64(values, tag: keyValue)
    }

    func encode(_ values: [Data], forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeRepeatedData(values, tag: keyValue)
    }

    func encode(_ values: [String], forKey key: Key) throws {
        let keyValue = try convertToProtobufferFieldNumber(key)
        try encodeRepeatedString(values, tag: keyValue)
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        let keyValue = try convertToProtobufferFieldNumber(key)
        // we need to switch here to also be able to encode structs with generic types
        // if struct has generic type, this will always end up here
        if T.self == Data.self, let value = value as? Data {
            // simply a byte array
            // prepend an extra byte containing the length
            var length = Data([UInt8(value.count)])
            length.append(value)
            appendData(length, tag: keyValue, wireType: .lengthDelimited)
        } else if isPrimitiveSupportedArray(T.self) {
            try encodeArray(value, forKey: key)
        } else if isOptional(T.self) {
            try encodeOptional(value, tag: keyValue)
        } else if isPrimitiveSupported(T.self) {
            try encodePrimitive(value, forKey: key)
        } else if [
                    Int8.self, Int16.self,
                    UInt8.self, UInt16.self,
                    [Int8].self, [Int16].self,
                    [UInt8].self, [UInt16].self,
                    [String].self
        ].contains(where: { $0 == T.self }) {
            throw ProtoError.decodingError("Encoding values of type \(T.self) is not supported yet")
        } else {
            // nested message
            try encodeNestedMessage(value, tag: keyValue)
        }
    }

    private func encodePrimitive<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        if T.self == String.self, let value = value as? String {
            try encode(value, forKey: key)
        } else if T.self == Bool.self, let value = value as? Bool {
            try encode(value, forKey: key)
        } else if T.self == Int.self, let value = value as? Int {
            try encode(value, forKey: key)
        } else if T.self == Int32.self, let value = value as? Int32 {
            try encode(value, forKey: key)
        } else if T.self == Int64.self, let value = value as? Int64 {
            try encode(value, forKey: key)
        } else if T.self == UInt.self, let value = value as? UInt {
            try encode(value, forKey: key)
        } else if T.self == UInt32.self, let value = value as? UInt32 {
            try encode(value, forKey: key)
        } else if T.self == UInt64.self, let value = value as? UInt64 {
            try encode(value, forKey: key)
        } else if T.self == Double.self, let value = value as? Double {
            try encode(value, forKey: key)
        } else if T.self == Float.self, let value = value as? Float {
            try encode(value, forKey: key)
        }
    }

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable discouraged_optional_boolean
    private func encodeArray<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        if T.self == [Bool].self, let value = value as? [Bool] {
            try encode(value, forKey: key)
        } else if T.self == [Float].self, let value = value as? [Float] {
            try encode(value, forKey: key)
        } else if T.self == [Double].self, let value = value as? [Double] {
            try encode(value, forKey: key)
        } else if T.self == [Int].self, let value = value as? [Int] {
            try encode(value, forKey: key)
        } else if T.self == [Int32].self, let value = value as? [Int32] {
            try encode(value, forKey: key)
        } else if T.self == [Int64].self, let value = value as? [Int64] {
            try encode(value, forKey: key)
        } else if T.self == [UInt].self, let value = value as? [UInt] {
            try encode(value, forKey: key)
        } else if T.self == [UInt32].self, let value = value as? [UInt32] {
            try encode(value, forKey: key)
        } else if T.self == [UInt64].self, let value = value as? [UInt64] {
            try encode(value, forKey: key)
        } else if T.self == [Data].self, let value = value as? [Data] {
            try encode(value, forKey: key)
        } else if T.self == [String].self, let value = value as? [String] {
            try encode(value, forKey: key)
        } else if T.self == [Bool?].self, let value = value as? [Bool?] {
            try encode(value.compactMap { $0 }, forKey: key)
        } else if T.self == [Float?].self, let value = value as? [Float?] {
            try encode(value.compactMap { $0 }, forKey: key)
        } else if T.self == [Double?].self, let value = value as? [Double?] {
            try encode(value.compactMap { $0 }, forKey: key)
        } else if T.self == [Int?].self, let value = value as? [Int?] {
            try encode(value.compactMap { $0 }, forKey: key)
        } else if T.self == [Int32?].self, let value = value as? [Int32?] {
            try encode(value.compactMap { $0 }, forKey: key)
        } else if T.self == [Int64?].self, let value = value as? [Int64?] {
            try encode(value.compactMap { $0 }, forKey: key)
        } else if T.self == [UInt?].self, let value = value as? [UInt?] {
            try encode(value.compactMap { $0 }, forKey: key)
        } else if T.self == [UInt32?].self, let value = value as? [UInt32?] {
            try encode(value.compactMap { $0 }, forKey: key)
        } else if T.self == [UInt64?].self, let value = value as? [UInt64?] {
            try encode(value.compactMap { $0 }, forKey: key)
        } else if T.self == [Data?].self, let value = value as? [Data?] {
            try encode(value.compactMap { $0 }, forKey: key)
        } else if T.self == [String?].self, let value = value as? [String?] {
            try encode(value.compactMap { $0 }, forKey: key)
        }
    }
    // swiftlint:enable cyclomatic_complexity

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key)
    -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        InternalProtoEncoder().container(keyedBy: keyType)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        InternalProtoEncoder().unkeyedContainer()
    }

    func superEncoder() -> Encoder {
        encoder
    }

    func superEncoder(forKey key: Key) -> Encoder {
        encoder
    }
}
