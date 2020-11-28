//
//  UnkeyedProtoDecodingContainer.swift
//
//
//  Created by Moritz Schüll on 20.11.20.
//

import Foundation


class UnkeyedProtoDecodingContainer: UnkeyedDecodingContainer {
    var codingPath: [CodingKey]
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


    init(from data: [Data], keyedBy keys: [Int], referencedBy: Data? = nil, codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.currentIndex = 0
        self.keys = keys
        self.values = data
        self.referencedBy = referencedBy
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
        var zeroInt = 0
        let zeroData = Data(bytes: &zeroInt,
                            count: MemoryLayout.size(ofValue: zeroInt))
        if let value = popNext(),
           value != zeroData {
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
            return value.withUnsafeBytes({ (rawPtr: UnsafeRawBufferPointer) in
                return rawPtr.load(as: Double.self)
            })
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Float.Type) throws -> Float {
        if let value = popNext() {
            return value.withUnsafeBytes({ (rawPtr: UnsafeRawBufferPointer) in
                return rawPtr.load(as: Float.self)
            })
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Int.Type) throws -> Int {
        if let value = popNext() {
            return value.withUnsafeBytes({ (rawPtr: UnsafeRawBufferPointer) in
                return rawPtr.load(as: Int.self)
            })
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        throw ProtoError.decodingError("Int8 not supported")
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        throw ProtoError.decodingError("Int16 not supported")
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        if let value = popNext() {
            return value.withUnsafeBytes({ (rawPtr: UnsafeRawBufferPointer) in
                return rawPtr.load(as: Int32.self)
            })
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        if let value = popNext() {
            return value.withUnsafeBytes({ (rawPtr: UnsafeRawBufferPointer) in
                return rawPtr.load(as: Int64.self)
            })
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        if let value = popNext() {
            return value.withUnsafeBytes({ (rawPtr: UnsafeRawBufferPointer) in
                return rawPtr.load(as: UInt.self)
            })
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        throw ProtoError.decodingError("UInt8 not supported")
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        throw ProtoError.decodingError("UInt16 not supported")
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        if let value = popNext() {
            return value.withUnsafeBytes({ (rawPtr: UnsafeRawBufferPointer) in
                return rawPtr.load(as: UInt32.self)
            })
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        if let value = popNext() {
            return value.withUnsafeBytes({ (rawPtr: UnsafeRawBufferPointer) in
                return rawPtr.load(as: UInt64.self)
            })
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        // we encountered a nested structure
        if let value = popNext() {
            return try ProtoDecoder().decode(type, from: value)
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
