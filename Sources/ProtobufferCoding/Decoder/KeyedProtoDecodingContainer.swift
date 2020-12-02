//
//  KeyedProtoDecodingContainer.swift
//
//
//  Created by Moritz Schüll on 19.11.20.
//

import Foundation

class KeyedProtoDecodingContainer<Key: CodingKey>: InternalProtoDecodingContainer, KeyedDecodingContainerProtocol {
    var allKeys: [Key]
    let data: [Int: [Data]]
    let referencedBy: Data?

    init(from data: [Int: [Data]], codingPath: [CodingKey] = [], referencedBy: Data? = nil) {
        self.data = data
        self.referencedBy = referencedBy
        allKeys = []

        super.init(codingPath: codingPath)
    }

    /// Tries to convert the given CodingKey to an Int, using the following steps:
    ///  - extract Int raw value, if possible
    ///  - convert to ProtoCodingKey and call mapCodingKey, if possible
    ///  - throws ProtoError.unknownCodingKey, if none of the above works
    private func extractIntValue(from key: Key) throws -> Int {
        codingPath.append(key)
        if let keyValue = key.intValue {
            return keyValue
        } else if let protoKey = key as? ProtoCodingKey {
            return try type(of: protoKey).protoRawValue(key)
        }
        throw ProtoError.unknownCodingKey(key)
    }

    func contains(_ key: Key) -> Bool {
        do {
            let keyValue = try extractIntValue(from: key)
            return data.keys.contains(keyValue)
        } catch {
            return false
        }
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        false
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last,
           value.first != 0 {
            return true
        }
        return false
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last,
           let output = String(data: value, encoding: .utf8) {
            return output
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Data.Type, forKey key: Key) throws -> Data {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last {
            return value
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last {
            return try decodeDouble(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last {
            return try decodeFloat(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        throw ProtoError.decodingError("Int not supported, use Int32 or Int64")
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        throw ProtoError.decodingError("Int not supported, use Int32 or Int64")
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        throw ProtoError.decodingError("Int not supported, use Int32 or Int64")
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last {
            return try decodeInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last {
            return try decodeInt64(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        throw ProtoError.decodingError("UInt not supported, use UInt32 or UInt64")
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        throw ProtoError.decodingError("UInt8 not supported, use UInt32 or UInt64")
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        throw ProtoError.decodingError("UInt8 not supported, use UInt32 or UInt64")
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last {
            return try decodeUInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last {
            return try decodeUInt64(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Bool].Type, forKey key: Key) throws -> [Bool] {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last {
            return try decodeRepeatedBool(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Float].Type, forKey key: Key) throws -> [Float] {
        let keyValue = try extractIntValue(from: key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedFloat(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Double].Type, forKey key: Key) throws -> [Double] {
        let keyValue = try extractIntValue(from: key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedDouble(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Int32].Type, forKey key: Key) throws -> [Int32] {
        let keyValue = try extractIntValue(from: key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Int64].Type, forKey key: Key) throws -> [Int64] {
        let keyValue = try extractIntValue(from: key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedInt64(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [UInt32].Type, forKey key: Key) throws -> [UInt32] {
        let keyValue = try extractIntValue(from: key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedUInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [UInt64].Type, forKey key: Key) throws -> [UInt64] {
        let keyValue = try extractIntValue(from: key)
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = data[keyValue]?.last {
            return try decodeRepeatedUInt64(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Data].Type, forKey key: Key) throws -> [Data] {
        let keyValue = try extractIntValue(from: key)
        if let values = data[keyValue] {
            // the data is already [Data] :D
            return values
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [String].Type, forKey key: Key) throws -> [String] {
        let keyValue = try extractIntValue(from: key)
        if let values = data[keyValue] {
            return decodeRepeatedString(values)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    // swiftlint:disable cyclomatic_complexity
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        // we need to switch here to also be able to decode structs with generic types
        // if struct has generic type, this will always end up here
        if T.self == Data.self, let value = try decode(Data.self, forKey: key) as? T {
            // this is simply a byte array
            return value
        } else if T.self == String.self, let value = try decode(String.self, forKey: key) as? T {
            return value
        } else if T.self == Bool.self, let value = try decode(Bool.self, forKey: key) as? T {
            return value
        } else if T.self == Int32.self, let value = try decode(Int32.self, forKey: key) as? T {
            return value
        } else if T.self == Int64.self, let value = try decode(Int64.self, forKey: key) as? T {
            return value
        } else if T.self == UInt32.self, let value = try decode(UInt32.self, forKey: key) as? T {
            return value
        } else if T.self == UInt64.self, let value = try decode(UInt64.self, forKey: key) as? T {
            return value
        } else if T.self == Double.self, let value = try decode(Double.self, forKey: key) as? T {
            return value
        } else if T.self == Float.self, let value = try decode(Float.self, forKey: key) as? T {
            return value
        } else if T.self == [Bool].self, let value = try decode([Bool].self, forKey: key) as? T {
            return value
        } else if T.self == [Float].self, let value = try decode([Float].self, forKey: key) as? T {
            return value
        } else if T.self == [Double].self, let value = try decode([Double].self, forKey: key) as? T {
            return value
        } else if T.self == [Int32].self, let value = try decode([Int32].self, forKey: key) as? T {
            return value
        } else if T.self == [Int64].self, let value = try decode([Int64].self, forKey: key) as? T {
            return value
        } else if T.self == [UInt32].self, let value = try decode([UInt32].self, forKey: key) as? T {
            return value
        } else if T.self == [UInt64].self, let value = try decode([UInt64].self, forKey: key) as? T {
            return value
        } else if T.self == [String].self, let value = try decode([String].self, forKey: key) as? T {
            return value
        } else if T.self == [Data].self, let value = try decode([Data].self, forKey: key) as? T {
            return value
        } else if [
                    Int.self, Int8.self, Int16.self,
                    UInt.self, UInt8.self, UInt16.self,
                    [Int].self, [Int8].self, [Int16].self,
                    [UInt].self, [UInt8].self, [UInt16].self
        ].contains(where: { $0 == T.self }) {
            throw ProtoError.decodingError("Decoding values of type \(T.self) is not supported yet")
        } else {
            // we encountered a nested structure
            let keyValue = try extractIntValue(from: key)
            if let value = data[keyValue]?.last {
                return try ProtoDecoder().decode(type, from: value)
            }
        }
        throw ProtoError.decodingError("No data for given key")
    }
    // swiftlint:enable cyclomatic_complexity

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
    -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last {
            return try InternalProtoDecoder(from: value).container(keyedBy: type)
        }
        throw ProtoError.unsupportedDataType("nestedContainer not available")
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        let keyValue = try extractIntValue(from: key)
        if let value = data[keyValue]?.last {
            return try InternalProtoDecoder(from: value).unkeyedContainer()
        }
        throw ProtoError.unsupportedDataType("nestedUnkeyedContainer not available")
    }

    func superDecoder() throws -> Decoder {
        if let referencedBy = referencedBy {
            return InternalProtoDecoder(from: referencedBy)
        }
        throw ProtoError.unsupportedDecodingStrategy("Cannot decode super")
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        try superDecoder()
    }
}
