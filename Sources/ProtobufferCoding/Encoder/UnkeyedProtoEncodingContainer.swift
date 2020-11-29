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
        if value {
            let byte: [UInt8] = [1]
            appendData(Data(byte), tag: currentFieldTag, wireType: .varInt)
            currentFieldTag += 1
        }
        // false is simply not appended to message
    }

    func encode(_ value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw ProtoError.decodingError("Cannot UTF8 encode given value")
        }
        // prepend an extra byte containing the length
        var length = Data([UInt8(data.count)])
        length.append(data)
        appendData(length, tag: currentFieldTag, wireType: WireType.lengthDelimited)
        currentFieldTag += 1
    }

    func encode(_ value: Double) throws {
        let data = encodeDouble(value)
        appendData(data, tag: currentFieldTag, wireType: WireType.bit64)
        currentFieldTag += 1
    }

    func encode(_ value: Float) throws {
        let data = encodeFloat(value)
        appendData(data, tag: currentFieldTag, wireType: WireType.bit64)
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
        let data = encodeVarInt(value: UInt64(bitPattern: Int64(value)))
        appendData(data, tag: currentFieldTag, wireType: .varInt)
        currentFieldTag += 1
    }

    func encode(_ value: Int64) throws {
        let data = encodeVarInt(value: UInt64(bitPattern: Int64(value)))
        appendData(data, tag: currentFieldTag, wireType: .varInt)
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
        let data = encodeVarInt(value: UInt64(value))
        appendData(data, tag: currentFieldTag, wireType: .varInt)
        currentFieldTag += 1
    }

    func encode(_ value: UInt64) throws {
        let data = encodeVarInt(value: value)
        appendData(data, tag: currentFieldTag, wireType: .varInt)
        currentFieldTag += 1
    }

    func encode(_ value: [UInt8]) throws {
        let data = Data(value)
        appendData(data, tag: currentFieldTag, wireType: .lengthDelimited)
        currentFieldTag += 1
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        // we need to switch here to also be able to encode structs with generic types
        // if struct has generic type, this will always end up here
        if T.self == Data.self,
           let value = value as? Data {
            // simply a byte array
            // prepend an extra byte containing the length
            var length = Data([UInt8(value.count)])
            length.append(value)
            appendData(length, tag: currentFieldTag, wireType: .lengthDelimited)
            currentFieldTag += 1
        } else if T.self == String.self,
                  let value = value as? String {
            return try encode(value)
        } else if T.self == Bool.self,
                  let value = value as? Bool {
            return try encode(value)
        } else if T.self == Int32.self,
                  let value = value as? Int32 {
            return try encode(value)
        } else if T.self == Int64.self,
                  let value = value as? Int64 {
            return try encode(value)
        } else if T.self == UInt32.self,
                  let value = value as? UInt32 {
            return try encode(value)
        } else if T.self == UInt64.self,
                  let value = value as? UInt64 {
            return try encode(value)
        } else if T.self == Double.self,
                  let value = value as? Double {
            return try encode(value)
        } else if T.self == Float.self,
                  let value = value as? Float {
            return try encode(value)
        } else {
            // nested message
            let encoder = InternalProtoEncoder()
            try value.encode(to: encoder)
            let data = try encoder.getEncoded()
            // prepend an extra byte containing the length
            var length = Data([UInt8(data.count)])
            length.append(data)
            appendData(length, tag: currentFieldTag, wireType: .lengthDelimited)
            currentFieldTag += 1
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
