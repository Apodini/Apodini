//
//  ProtoEncodingContainer.swift
//
//
//  Created by Moritz Schüll on 28.11.20.
//

import Foundation


/// Offers basic functionality shared by several encoding containers for Protobuffers.
internal class InternalProtoEncodingContainer {
    /// The path of coding keys taken to get to this point in encoding.
    var codingPath: [CodingKey] = []
    var encoder: InternalProtoEncoder


    public init(using encoder: InternalProtoEncoder, codingPath: [CodingKey]) {
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

    /// Taken & adapted from https://github.com/apple/swift-protobuf/blob/master/Sources/SwiftProtobuf/BinaryEncoder.swift
    ///
    /// Encodes a number as a Protobuffer VarInt.
    /// See Protobuffer documentation for details on VarInts: https://developers.google.com/protocol-buffers/docs/encoding#varints
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
    public func appendData(_ value: Data, tag: Int, wireType: WireType) {
        let prefix = UInt8((tag << 3) | wireType.rawValue) // each value is prefixed by 1 byte: 5 bit of tag, 3 bit of type
        var value = value
        value.insert(prefix, at: 0) // add the prefix at the beginning of the value
        encoder.append(value)
    }

    public func encodeBool(_ value: Bool, tag: Int) throws {
        if value {
            let byte = UInt8(1)
            appendData(Data([byte]), tag: tag, wireType: .varInt)
        }
        // false is simply not appended to message
    }

    public func encodeString(_ value: String, tag: Int) throws {
        guard var data = value.data(using: .utf8) else {
            throw ProtoError.encodingError("Cannot encode data for given key")
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    public func encodeFloat(_ value: Float, tag: Int) throws {
        let data = _encodeFloat(value)
        appendData(data, tag: tag, wireType: WireType.bit32)
    }

    public func encodeDouble(_ value: Double, tag: Int) throws {
        let data = _encodeDouble(value)
        appendData(data, tag: tag, wireType: WireType.bit64)
    }

    public func encodeInt32(_ value: Int32, tag: Int) throws {
        // we need to encode it as VarInt (run-length encoded number)
        let data = encodeVarInt(value: UInt64(bitPattern: Int64(value)))
        appendData(data, tag: tag, wireType: .varInt)
    }

    public func encodeInt64(_ value: Int64, tag: Int) throws {
        // we need to encode it as VarInt (run-length encoded number)
        let data = encodeVarInt(value: UInt64(bitPattern: Int64(value)))
        appendData(data, tag: tag, wireType: .varInt)
    }

    public func encodeUInt32(_ value: UInt32, tag: Int) throws {
        // we need to encode it as VarInt (run-length encoded number)
        let data = encodeVarInt(value: UInt64(value))
        appendData(data, tag: tag, wireType: .varInt)
    }

    public func encodeUInt64(_ value: UInt64, tag: Int) throws {
        // we need to encode it as VarInt (run-length encoded number)
        let data = encodeVarInt(value: value)
        appendData(data, tag: tag, wireType: .varInt)
    }

    public func encodeRepeatedBool(_ values: [Bool], tag: Int) throws {
        var data = Data()
        // one byte for each boolean value
        for value in values {
            let byte = UInt8(value ? 1 : 0)
            data.append(byte)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    public func encodeRepeatedDouble(_ values: [Double], tag: Int) throws {
        var data = Data()
        for value in values {
            let double = _encodeDouble(value)
            data.append(double)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    public func encodeRepeatedFloat(_ values: [Float], tag: Int) throws {
        var data = Data()
        for value in values {
            let float = _encodeFloat(value)
            data.append(float)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    public func encodeRepeatedInt32(_ values: [Int32], tag: Int) throws {
        var data = Data()
        for value in values {
            let int32 = encodeVarInt(value: UInt64(bitPattern: Int64(value)))
            data.append(int32)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    public func encodeRepeatedInt64(_ values: [Int64], tag: Int) throws {
        var data = Data()
        for value in values {
            let int64 = encodeVarInt(value: UInt64(bitPattern: value))
            data.append(int64)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    public func encodeRepeatedUInt32(_ values: [UInt32], tag: Int) throws {
        var data = Data()
        for value in values {
            let uint32 = encodeVarInt(value: UInt64(value))
            data.append(uint32)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    public func encodeRepeatedUInt64(_ values: [UInt64], tag: Int) throws {
        var data = Data()
        for value in values {
            let uint64 = encodeVarInt(value: value)
            data.append(uint64)
        }
        data = prependLength(data)
        appendData(data, tag: tag, wireType: .lengthDelimited)
    }

    public func encodeRepeatedData(_ values: [Data], tag: Int) throws {
        // nothing special here, just append all the data items as length-delimited
        for value in values {
            // prepend an extra byte containing the length
            appendData(prependLength(value), tag: tag, wireType: .lengthDelimited)
        }
    }

    public func encodeRepeatedString(_ values: [String], tag: Int) throws {
        // nothing special here, just append all the data strings as length-delimited
        for value in values {
            try encodeString(value, tag: tag)
        }
    }

    public func encodeNestedMessage<T: Encodable>(_ value: T, tag: Int) throws {
        let encoder = InternalProtoEncoder()
        try value.encode(to: encoder)
        let data = try encoder.getEncoded()
        // prepend an extra byte containing the length
        appendData(prependLength(data), tag: tag, wireType: .lengthDelimited)
    }
}
