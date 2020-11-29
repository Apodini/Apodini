//
//  KeyedProtoDecodingContainer.swift
//
//
//  Created by Moritz Schüll on 19.11.20.
//

import Foundation


class KeyedProtoDecodingContainer<Key: CodingKey>: InternalProtoDecodingContainer, KeyedDecodingContainerProtocol {
    var allKeys: [Key]
    let data: [Int: Data]
    let referencedBy: Data?

    init(from data: [Int: Data], codingPath: [CodingKey] = [], referencedBy: Data? = nil) {
        self.data = data
        self.referencedBy = referencedBy
        allKeys = []

        super.init(codingPath: codingPath)
    }

    private func extractIntValue(from key: Key) -> Int? {
        codingPath.append(key)
        do {
            if let keyValue = key.intValue {
                return keyValue
            } else if let protoKey = key as? ProtoCodingKey {
                return try type(of: protoKey).mapCodingKey(key)
            }
        } catch(_) {
            print("Error extracting Int value from CodingKey")
        }
        return nil
    }



    func contains(_ key: Key) -> Bool {
        if let keyValue = extractIntValue(from: key) {
            return data.keys.contains(keyValue)
        }
        return false
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        return false
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        if let keyValue = extractIntValue(from: key),
           let value = data[keyValue],
           value[0] != 0 {
            return true
        }
        return false
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        if let keyValue = extractIntValue(from: key),
           let value = data[keyValue] {
            return String(data: value, encoding: .utf8)!
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Data.Type, forKey key: Key) throws -> Data {
        if let keyValue = extractIntValue(from: key),
           let value = data[keyValue] {
            return value
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        if let keyValue = extractIntValue(from: key),
           let value = data[keyValue] {
            return try decodeDouble(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        if let keyValue = extractIntValue(from: key),
           let value = data[keyValue] {
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
        if let keyValue = extractIntValue(from: key),
           let value = data[keyValue] {
            return try decodeInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        if let keyValue = extractIntValue(from: key),
           let value = data[keyValue] {
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
        if let keyValue = extractIntValue(from: key),
           let value = data[keyValue] {
            return try decodeUInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        if let keyValue = extractIntValue(from: key),
           let value = data[keyValue] {
            return try decodeUInt64(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        // we need to switch here to also be able to decode structs with generic types
        // if struct has generic type, this will always end up here
        if T.self == Data.self {
            // this is simply a byte array
            return try decode(Data.self, forKey: key) as! T
        } else if T.self == String.self {
            return try decode(String.self, forKey: key) as! T
        } else if T.self == Bool.self {
            return try decode(Bool.self, forKey: key) as! T
        } else if T.self == Int32.self {
            return try decode(Int32.self, forKey: key) as! T
        } else if T.self == Int64.self {
            return try decode(Int64.self, forKey: key) as! T
        } else if T.self == UInt32.self {
            return try decode(UInt32.self, forKey: key) as! T
        } else if T.self == UInt64.self {
            return try decode(UInt64.self, forKey: key) as! T
        } else if T.self == Double.self {
            return try decode(Double.self, forKey: key) as! T
        } else if T.self == Float.self {
            return try decode(Float.self, forKey: key) as! T
        } else {
            // we encountered a nested structure
            if let keyValue = extractIntValue(from: key),
               let value = data[keyValue] {
                return try ProtoDecoder().decode(type, from: value)
            }
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        if let keyValue = extractIntValue(from: key),
           let value = data[keyValue] {
            return try InternalProtoDecoder(from: value).container(keyedBy: type)
        }
        throw ProtoError.unsupportedDataType("nestedContainer not available")
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        if let keyValue = extractIntValue(from: key),
           let value = data[keyValue] {
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
        return try superDecoder()
    }
}
