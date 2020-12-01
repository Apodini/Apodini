//
//  UnkeyedProtoEncodingContainer.swift
//
//
//  Created by Moritz Schüll on 28.11.20.
//

import Foundation


class UnkeyedProtoEncodingContainer: InternalProtoEncodingContainer, UnkeyedEncodingContainer {
    var currentFieldTag: Int

    var count: Int {
        return currentFieldTag
    }


    override init(using encoder: InternalProtoEncoder, codingPath: [CodingKey]) {
        self.currentFieldTag = 1

        super.init(using: encoder, codingPath: codingPath)
    }

    func encodeNil() throws {
        // cannot encode nil
        throw ProtoError.encodingError("Cannot encode nil")
    }

    func encode(_ value: Bool) throws {
        try encodeBool(value, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ value: String) throws {
        try encodeString(value, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ value: Double) throws {
        try encodeDouble(value, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ value: Float) throws {
        try encodeFloat(value, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ value: Int) throws {
        throw ProtoError.encodingError("Int not supported, use Int32 or Int64")
    }

    func encode(_ value: Int8) throws {
        throw ProtoError.encodingError("Int8 not supported, use Int32 or Int64")
    }

    func encode(_ value: Int16) throws {
        throw ProtoError.encodingError("Int16 not supported, use Int32 or Int64")
    }

    func encode(_ value: Int32) throws {
        try encodeInt32(value, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ value: Int64) throws {
        try encodeInt64(value, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ value: UInt) throws {
        throw ProtoError.decodingError("UInt not supported, use UInt32 or UInt64")
    }

    func encode(_ value: UInt8) throws {
        throw ProtoError.decodingError("UInt8 not supported, use UInt32 or UInt64")
    }

    func encode(_ value: UInt16) throws {
        throw ProtoError.decodingError("UInt16 not supported, use UInt32 or UInt64")
    }

    func encode(_ value: UInt32) throws {
        try encodeUInt32(value, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ value: UInt64) throws {
        try encodeUInt64(value, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ values: [Bool]) throws {
        try encodeRepeatedBool(values, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ values: [Double]) throws {
        try encodeRepeatedDouble(values, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ values: [Float]) throws {
        try encodeRepeatedFloat(values, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ values: [Int32]) throws {
        try encodeRepeatedInt32(values, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ values: [Int64]) throws {
        try encodeRepeatedInt64(values, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ values: [UInt32]) throws {
        try encodeRepeatedUInt32(values, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ values: [UInt64]) throws {
        try encodeRepeatedUInt64(values, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ values: [Data]) throws {
        try encodeRepeatedData(values, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode(_ values: [String]) throws {
        try encodeRepeatedString(values, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encodeNested<T: Encodable>(_ value: T) throws {
        try encodeNestedMessage(value, tag: currentFieldTag)
        currentFieldTag += 1
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        // we need to switch here to also be able to encode structs with generic types
        // if struct has generic type, this will always end up here
        if T.self == Data.self, let value = value as? Data {
            // simply a byte array
            // prepend an extra byte containing the length
            var length = Data([UInt8(value.count)])
            length.append(value)
            appendData(length, tag: currentFieldTag, wireType: .lengthDelimited)
            currentFieldTag += 1
        } else if T.self == String.self, let value = value as? String {
            try encode(value)
        } else if T.self == Bool.self, let value = value as? Bool {
            try encode(value)
        } else if T.self == Int32.self, let value = value as? Int32 {
            try encode(value)
        } else if T.self == Int64.self, let value = value as? Int64 {
            try encode(value)
        } else if T.self == UInt32.self, let value = value as? UInt32 {
            try encode(value)
        } else if T.self == UInt64.self, let value = value as? UInt64 {
            try encode(value)
        } else if T.self == Double.self, let value = value as? Double {
            try encode(value)
        } else if T.self == Float.self, let value = value as? Float {
            try encode(value)
        } else if T.self == [Bool].self, let value = value as? [Bool] {
            try encode(value)
        } else if T.self == [Float].self, let value = value as? [Float] {
            try encode(value)
        } else if T.self == [Double].self, let value = value as? [Double] {
            try encode(value)
        } else if T.self == [Int32].self, let value = value as? [Int32] {
            try encode(value)
        } else if T.self == [Int64].self, let value = value as? [Int64] {
            try encode(value)
        } else if T.self == [UInt32].self, let value = value as? [UInt32] {
            try encode(value)
        } else if T.self == [UInt64].self, let value = value as? [UInt64] {
            try encode(value)
        } else if T.self == [Data].self, let value = value as? [Data] {
            try encode(value)
        } else if T.self == [String].self, let value = value as? [String] {
            try encode(value)
        } else if [Int.self, Int8.self, Int16.self,
                   UInt.self, UInt8.self, UInt16.self,
                   [Int].self, [Int8].self, [Int16].self,
                   [UInt].self, [UInt8].self, [UInt16].self,
                   [String].self].contains(where: { $0 == T.self }) {
            throw ProtoError.decodingError("Encoding values of type \(T.self) is not supported yet")
        } else {
            // nested message
            try encodeNested(value)
        }
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        return InternalProtoEncoder().container(keyedBy: keyType)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return InternalProtoEncoder().unkeyedContainer()
    }

    func superEncoder() -> Encoder {
        encoder
    }
}
