//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

/// Offers basic functionality shared by several encoding containers for Protobuffers.
internal class InternalProtoEncodingContainer {
    /// The path of coding keys taken to get to this point in encoding.
    var codingPath: [CodingKey] = []
    var encoder: InternalProtoEncoder

    internal init(using encoder: InternalProtoEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }

    /// Prepends a VarInt to the given data, that contains the length of the given data
    private func prependLength(_ data: Data) -> Data {
        let length = UInt64(data.count)
        var lenVarInt = encodeVarInt(value: length)
        lenVarInt.append(data)
        return lenVarInt
    }

    /// Taken & adapted from
    /// https://github.com/apple/swift-protobuf/blob/master/Sources/SwiftProtobuf/BinaryEncoder.swift
    ///
    /// Encodes a number as a Protobuffer VarInt.
    /// See Protobuffer documentation for details on VarInts:
    /// https://developers.google.com/protocol-buffers/docs/encoding#varints
    private func encodeVarInt(value: UInt64) -> Data {
        var output = [UInt8]()
        var value = value
        while value > 127 {
            output.append(UInt8(value & 0b01111111 | 0b10000000))
            value >>= 7
        }
        output.append(UInt8(value))
        return Data(output)
    }

    private func _encodeFloat(_ value: Float) -> Data {
        let size = MemoryLayout<Float>.size
        var value = value
        var nativeBytes: UInt32 = 0
        memcpy(&nativeBytes, &value, size)
        var littleEndianBytes = nativeBytes.littleEndian
        return withUnsafeBytes(of: &littleEndianBytes, { Data($0) })
    }

    private func _encodeDouble(_ value: Double) -> Data {
        let size = MemoryLayout<Double>.size
        var value = value
        var nativeBytes: UInt64 = 0
        memcpy(&nativeBytes, &value, size)
        var littleEndianBytes = nativeBytes.littleEndian
        return withUnsafeBytes(of: &littleEndianBytes, { Data($0) })
    }

    /// Adds the necessary wire-type and field-tag to the given value and appends it to the encoder.
    /// - Parameter prefixType: Switch to disable the functionality to prepend the wiretype and field-tag
    internal func appendData(_ value: Data, tag: Int, wireType: WireType, prefixType: Bool = true) {
        if prefixType {
            // each value is prefixed by 1 byte: 5 bit of tag, 3 bit of type
            let prefix = UInt8((tag << 3) | wireType.rawValue)
            var value = value
            value.insert(prefix, at: 0) // add the prefix at the beginning of the value
            encoder.append(value)
        } else {
            encoder.append(value)
        }
    }

    internal func encodeBool(_ value: Bool, tag: Int) throws {
        if value {
            let byte = UInt8(1)
            appendData(Data([byte]), tag: tag, wireType: .varInt)
        }
        // false is simply not appended to message
    }

    internal func encodeString(_ value: String, tag: Int) throws {
        guard var data = value.data(using: .utf8) else {
            throw ProtoError.encodingError("Cannot encode data for given key")
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    internal func encodeFloat(_ value: Float, tag: Int) throws {
        let data = _encodeFloat(value)
        appendData(data, tag: tag, wireType: WireType.bit32)
    }

    internal func encodeDouble(_ value: Double, tag: Int) throws {
        let data = _encodeDouble(value)
        appendData(data, tag: tag, wireType: WireType.bit64)
    }

    internal func encodeInt(_ value: Int, tag: Int) throws {
        switch encoder.integerWidthCodingStrategy {
        case .thirtyTwo:
            try encodeInt32(Int32(value), tag: tag)
        case .sixtyFour:
            try encodeInt64(Int64(value), tag: tag)
        }
    }

    internal func encodeInt32(_ value: Int32, tag: Int) throws {
        // we need to encode it as VarInt (run-length encoded number)
        let data = encodeVarInt(value: UInt64(bitPattern: Int64(value)))
        appendData(data, tag: tag, wireType: .varInt)
    }

    internal func encodeInt64(_ value: Int64, tag: Int) throws {
        // we need to encode it as VarInt (run-length encoded number)
        let data = encodeVarInt(value: UInt64(bitPattern: Int64(value)))
        appendData(data, tag: tag, wireType: .varInt)
    }

    internal func encodeUInt(_ value: UInt, tag: Int) throws {
        switch encoder.integerWidthCodingStrategy {
        case .thirtyTwo:
            try encodeUInt32(UInt32(value), tag: tag)
        case .sixtyFour:
            try encodeUInt64(UInt64(value), tag: tag)
        }
    }

    internal func encodeUInt32(_ value: UInt32, tag: Int) throws {
        // we need to encode it as VarInt (run-length encoded number)
        let data = encodeVarInt(value: UInt64(value))
        appendData(data, tag: tag, wireType: .varInt)
    }

    internal func encodeUInt64(_ value: UInt64, tag: Int) throws {
        // we need to encode it as VarInt (run-length encoded number)
        let data = encodeVarInt(value: value)
        appendData(data, tag: tag, wireType: .varInt)
    }

    internal func encodeRepeatedBool(_ values: [Bool], tag: Int) throws {
        var data = Data()
        // one byte for each boolean value
        for value in values {
            let byte = UInt8(value ? 1 : 0)
            data.append(byte)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    internal func encodeRepeatedDouble(_ values: [Double], tag: Int) throws {
        var data = Data()
        for value in values {
            let double = _encodeDouble(value)
            data.append(double)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    internal func encodeRepeatedFloat(_ values: [Float], tag: Int) throws {
        var data = Data()
        for value in values {
            let float = _encodeFloat(value)
            data.append(float)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    internal func encodeRepeatedInt(_ values: [Int], tag: Int) throws {
        switch encoder.integerWidthCodingStrategy {
        case .thirtyTwo:
            try encodeRepeatedInt32(values.compactMap { Int32($0) }, tag: tag)
        case .sixtyFour:
            try encodeRepeatedInt64(values.compactMap { Int64($0) }, tag: tag)
        }
    }

    internal func encodeRepeatedInt32(_ values: [Int32], tag: Int) throws {
        var data = Data()
        for value in values {
            let int32 = encodeVarInt(value: UInt64(bitPattern: Int64(value)))
            data.append(int32)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    internal func encodeRepeatedInt64(_ values: [Int64], tag: Int) throws {
        var data = Data()
        for value in values {
            let int64 = encodeVarInt(value: UInt64(bitPattern: value))
            data.append(int64)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    internal func encodeRepeatedUInt(_ values: [UInt], tag: Int) throws {
        switch encoder.integerWidthCodingStrategy {
        case .thirtyTwo:
            try encodeRepeatedUInt32(values.compactMap { UInt32($0) }, tag: tag)
        case .sixtyFour:
            try encodeRepeatedUInt64(values.compactMap { UInt64($0) }, tag: tag)
        }
    }

    internal func encodeRepeatedUInt32(_ values: [UInt32], tag: Int) throws {
        var data = Data()
        for value in values {
            let uint32 = encodeVarInt(value: UInt64(value))
            data.append(uint32)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    internal func encodeRepeatedUInt64(_ values: [UInt64], tag: Int) throws {
        var data = Data()
        for value in values {
            let uint64 = encodeVarInt(value: value)
            data.append(uint64)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    internal func encodeRepeatedData(_ values: [Data], tag: Int) throws {
        // nothing special here, just append all the data items as length-delimited
        for value in values {
            // prepend an extra byte containing the length
            appendData(prependLength(value), tag: tag, wireType: .lengthDelimited)
        }
    }

    internal func encodeRepeatedString(_ values: [String], tag: Int) throws {
        // nothing special here, just append all the data strings as length-delimited
        for value in values {
            try encodeString(value, tag: tag)
        }
    }

    internal func encodeOptional<T: Encodable>(_ value: T, tag: Int) throws {
        let encoder = InternalProtoEncoder()
        try value.encode(to: encoder)
        let data = try encoder.getEncoded()
        // append without any further length or type prefix
        // (this encoding layer was basically just used to unwrap the optional,
        // thus should not be reflected in the encoded byte-array)
        appendData(data, tag: tag, wireType: .lengthDelimited, prefixType: false)
    }

    internal func encodeNestedMessage<T: Encodable>(_ value: T, tag: Int) throws {
        let encoder = InternalProtoEncoder()
        try value.encode(to: encoder)
        let data = try encoder.getEncoded()
        // prepend an extra byte containing the length
        appendData(prependLength(data), tag: tag, wireType: .lengthDelimited)
    }
}
