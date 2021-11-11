//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

class KeyedProtoDecodingContainer<Key: CodingKey>: InternalProtoDecodingContainer, KeyedDecodingContainerProtocol {
    var allKeys: [Key]
    let data: [Int: [Data]]
    let referencedBy: Data?

    init(from data: [Int: [Data]],
         codingPath: [CodingKey] = [],
         integerWidthCodingStrategy: IntegerWidthCodingStrategy,
         referencedBy: Data? = nil) {
        self.data = data
        self.referencedBy = referencedBy
        allKeys = []

        super.init(codingPath: codingPath, integerWidthCodingStrategy: integerWidthCodingStrategy)
    }

    /// Tries to convert the given CodingKey to an Int, using the following steps:
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

    func contains(_ key: Key) -> Bool {
        do {
            let keyValue = try convertToProtobufferFieldNumber(key)
            return data.keys.contains(keyValue)
        } catch {
            return false
        }
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        false
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last,
           value.first != 0 {
            return true
        }
        return false
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last,
           let output = String(data: value, encoding: .utf8) {
            return output
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: Data.Type, forKey key: Key) throws -> Data {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last {
            return value
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last {
            return try decodeDouble(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last {
            return try decodeFloat(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        let keyValue = try convertToProtobufferFieldNumber(key)
        return try Int(from: data[keyValue]?.last, using: self)
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        throw ProtoError.decodingError("Int not supported, use Int32 or Int64")
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        throw ProtoError.decodingError("Int not supported, use Int32 or Int64")
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last {
            return try decodeInt32(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last {
            return try decodeInt64(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        let keyValue = try convertToProtobufferFieldNumber(key)
        return try UInt(from: data[keyValue]?.last, using: self)
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        throw ProtoError.decodingError("UInt8 not supported, use UInt32 or UInt64")
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        throw ProtoError.decodingError("UInt8 not supported, use UInt32 or UInt64")
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last {
            return try decodeUInt32(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last {
            return try decodeUInt64(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: [Bool].Type, forKey key: Key) throws -> [Bool] {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last {
            return try decodeRepeatedBool(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: [Float].Type, forKey key: Key) throws -> [Float] {
        let keyValue = try convertToProtobufferFieldNumber(key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedFloat(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: [Double].Type, forKey key: Key) throws -> [Double] {
        let keyValue = try convertToProtobufferFieldNumber(key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedDouble(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: [Int].Type, forKey key: Key) throws -> [Int] {
        let keyValue = try convertToProtobufferFieldNumber(key)
        return try [Int](from: data[keyValue]?.last, using: self)
    }

    func decode(_ type: [Int32].Type, forKey key: Key) throws -> [Int32] {
        let keyValue = try convertToProtobufferFieldNumber(key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedInt32(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: [Int64].Type, forKey key: Key) throws -> [Int64] {
        let keyValue = try convertToProtobufferFieldNumber(key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedInt64(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: [UInt].Type, forKey key: Key) throws -> [UInt] {
        let keyValue = try convertToProtobufferFieldNumber(key)
        return try [UInt](from: data[keyValue]?.last, using: self)
    }

    func decode(_ type: [UInt32].Type, forKey key: Key) throws -> [UInt32] {
        let keyValue = try convertToProtobufferFieldNumber(key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedUInt32(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: [UInt64].Type, forKey key: Key) throws -> [UInt64] {
        let keyValue = try convertToProtobufferFieldNumber(key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedUInt64(value)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: [Data].Type, forKey key: Key) throws -> [Data] {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let values = data[keyValue] {
            // the data is already [Data] :D
            return values
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode(_ type: [String].Type, forKey key: Key) throws -> [String] {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let values = data[keyValue] {
            return decodeRepeatedString(values)
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        // we need to switch here to also be able to decode structs with generic types
        // if struct has generic type, this will always end up here
        if isPrimitiveSupported(type) {
            return try decodePrimitive(type, forKey: key)
        } else if isPrimitiveSupportedArray(type) {
            return try decodeArray(type, forKey: key)
        } else if [
                    Int8.self, Int16.self,
                    UInt8.self, UInt16.self,
                    [Int8].self, [Int16].self,
                    [UInt8].self, [UInt16].self
        ].contains(where: { $0 == T.self }) {
            throw ProtoError.decodingError("Decoding values of type \(T.self) is not supported yet")
        } else {
            // we encountered a nested structure
            let keyValue = try convertToProtobufferFieldNumber(key)
            if let value = data[keyValue]?.last {
                return try ProtobufferDecoder().decode(type, from: value)
            }
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
    -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last {
            return try InternalProtoDecoder(from: value, with: integerWidthCodingStrategy).container(keyedBy: type)
        }
        throw ProtoError.unsupportedDataType("nestedContainer not available")
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        let keyValue = try convertToProtobufferFieldNumber(key)
        if let value = data[keyValue]?.last {
            return try InternalProtoDecoder(from: value, with: integerWidthCodingStrategy).unkeyedContainer()
        }
        throw ProtoError.unsupportedDataType("nestedUnkeyedContainer not available")
    }

    func superDecoder() throws -> Decoder {
        if let referencedBy = referencedBy {
            return InternalProtoDecoder(from: referencedBy, with: integerWidthCodingStrategy)
        }
        throw ProtoError.unsupportedDecodingStrategy("Cannot decode super")
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        try superDecoder()
    }
}

// MARK: - Type switching
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable discouraged_optional_boolean
extension KeyedProtoDecodingContainer {
    func decodePrimitive<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        if T.self == Data.self || T.self == Data?.self,
           let value = try decode(Data.self, forKey: key) as? T {
            return value
        } else if T.self == String.self || T.self == String?.self,
                  let value = try decode(String.self, forKey: key) as? T {
            return value
        } else if T.self == Bool.self || T.self == Bool?.self,
                  let value = try decode(Bool.self, forKey: key) as? T {
            return value
        } else if T.self == Int.self || T.self == Int?.self,
                  let value = try decode(Int.self, forKey: key) as? T {
            return value
        } else if T.self == Int32.self || T.self == Int32?.self,
                  let value = try decode(Int32.self, forKey: key) as? T {
            return value
        } else if T.self == Int64.self || T.self == Int64?.self,
                  let value = try decode(Int64.self, forKey: key) as? T {
            return value
        } else if T.self == UInt.self || T.self == UInt?.self,
                  let value = try decode(UInt.self, forKey: key) as? T {
            return value
        } else if T.self == UInt32.self || T.self == UInt32?.self,
                  let value = try decode(UInt32.self, forKey: key) as? T {
            return value
        } else if T.self == UInt64.self || T.self == UInt64?.self,
                  let value = try decode(UInt64.self, forKey: key) as? T {
            return value
        } else if T.self == Double.self || T.self == Double?.self,
                  let value = try decode(Double.self, forKey: key) as? T {
            return value
        } else if T.self == Float.self || T.self == Float?.self,
                  let value = try decode(Float.self, forKey: key) as? T {
            return value
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }

    func decodeArray<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        if T.self == [Bool].self || T.self == [Bool?].self,
           let value = try decode([Bool].self, forKey: key) as? T {
            return value
        } else if T.self == [Float].self || T.self == [Float?].self,
                  let value = try decode([Float].self, forKey: key) as? T {
            return value
        } else if T.self == [Double].self || T.self == [Double?].self,
                  let value = try decode([Double].self, forKey: key) as? T {
            return value
        } else if T.self == [Int].self || T.self == [Int?].self,
                  let value = try decode([Int].self, forKey: key) as? T {
            return value
        } else if T.self == [Int32].self || T.self == [Int32?].self,
                  let value = try decode([Int32].self, forKey: key) as? T {
            return value
        } else if T.self == [Int64].self || T.self == [Int64?].self,
                  let value = try decode([Int64].self, forKey: key) as? T {
            return value
        } else if T.self == [UInt].self || T.self == [UInt?].self,
                  let value = try decode([UInt].self, forKey: key) as? T {
            return value
        } else if T.self == [UInt32].self || T.self == [UInt32?].self,
                  let value = try decode([UInt32].self, forKey: key) as? T {
            return value
        } else if T.self == [UInt64].self || T.self == [UInt64?].self,
                  let value = try decode([UInt64].self, forKey: key) as? T {
            return value
        } else if T.self == [String].self || T.self == [String?].self,
                  let value = try decode([String].self, forKey: key) as? T {
            return value
        } else if T.self == [Data].self || T.self == [Data?].self,
                  let value = try decode([Data].self, forKey: key) as? T {
            return value
        }
        throw ProtoError.decodingError("No data for given key '\(key)'")
    }
}
// swiftlint:enable cyclomatic_complexity
