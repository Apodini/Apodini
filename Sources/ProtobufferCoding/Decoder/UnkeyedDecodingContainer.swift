//
//  UnkeyedProtoDecodingContainer.swift
//
//
//  Created by Moritz Schüll on 20.11.20.
//

import Foundation


class UnkeyedProtoDecodingContainer: InternalProtoDecodingContainer, UnkeyedDecodingContainer {
    var currentIndex: Int
    var keys: [Int]
    var values: [Data]
    let referencedBy: Data?

    var count: Int? {
        get {
            return values.count
        }
    }

    var isAtEnd: Bool {
        get {
            return currentIndex < values.count
        }
    }


    init(from data: [Data], keyedBy keys: [Int], codingPath: [CodingKey] = [], referencedBy: Data? = nil) {
        self.currentIndex = 0
        self.keys = keys
        self.values = data
        self.referencedBy = referencedBy

        super.init(codingPath: codingPath)
    }

    private func popNext() -> Data? {
        if !isAtEnd {
//            let key = keys[currentIndex]
            let data = values[currentIndex]
            currentIndex += 1
//            codingPath.append(key)
            return data
        }

        print("No more data to decode")
        return nil
    }

    func decodeNil() throws -> Bool {
        return false
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        if let value = popNext(),
           value[0] != 0 {
            return true
        }
        return false
    }

    func decode(_ type: String.Type) throws -> String {
        if let value = popNext() {
            return String(data: value, encoding: .utf8)!
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Double.Type) throws -> Double {
        if let value = popNext() {
            return try decodeDouble(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Float.Type) throws -> Float {
        if let value = popNext() {
            return try decodeFloat(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Int.Type) throws -> Int {
        throw ProtoError.decodingError("Int not supported, use Int32 or Int64")
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        throw ProtoError.decodingError("Int8 not supported, use Int32 or Int64")
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        throw ProtoError.decodingError("Int16 not supported, use Int32 or Int64")
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        if let value = popNext() {
            return try decodeInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        if let value = popNext() {
            return try decodeInt64(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        throw ProtoError.decodingError("UInt not supported, use UInt32 or UInt64")
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        throw ProtoError.decodingError("UInt8 not supported, use UInt32 or UInt64")
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        throw ProtoError.decodingError("UInt16 not supported, use UInt32 or UInt64")
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        if let value = popNext() {
            return try decodeUInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        if let value = popNext() {
            return try decodeUInt64(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if T.self == Data.self,
           let value = popNext() as? T {
            // this is simply a byte array
            return value
        } else {
            // we encountered a nested structure
            if let value = popNext() {
                return try ProtoDecoder().decode(type, from: value)
            }
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        if let value = popNext() {
            return try InternalProtoDecoder(from: value).container(keyedBy: type)
        }
        throw ProtoError.unsupportedDataType("nestedContainer not available")
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        if let value = popNext() {
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
}
