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

    /// Adds the necessary wire-type and field-tag to the given vaalue and appends it to the encoder.
    public func appendData(_ value: Data, tag: Int, wireType: WireType) {
        let prefix = UInt8((tag << 3) | wireType.rawValue) // each value is prefixed by 1 byte: 5 bit of tag, 3 bit of type
        var value = value
        value.insert(prefix, at: 0) // add the prefix at the beginning of the value
        encoder.append(value)
    }

    /// Taken & adapted from https://github.com/apple/swift-protobuf/blob/master/Sources/SwiftProtobuf/BinaryEncoder.swift
    ///
    /// Encodes a number as a Protobuffer VarInt.
    /// See Protobuffer documentation for details on VarInts: https://developers.google.com/protocol-buffers/docs/encoding#varints
    public func encodeVarInt(value: UInt64) -> Data {
        var output = [UInt8]()
        var value = value
        while value > 127 {
            output.append(UInt8(value & 0b01111111 | 0b10000000))
            value >>= 7
        }
        output.append(UInt8(value))
        return Data(output)
    }

    /// Converts a Swift Double to network-order bytes
    public func encodeDouble(_ value: Double) -> Data {
        let size = MemoryLayout<Double>.size
        var value = value
        var nativeBytes: UInt64 = 0
        memcpy(&nativeBytes, &value, size)
        var littleEndianBytes = nativeBytes.littleEndian
        return withUnsafeBytes(of: &littleEndianBytes, { Data($0) })
    }

    /// Converts a Swift Float  to network-order bytes
    public func encodeFloat(_ value: Float) -> Data {
        let size = MemoryLayout<Float>.size
        var value = value
        var nativeBytes: UInt32 = 0
        memcpy(&nativeBytes, &value, size)
        var littleEndianBytes = nativeBytes.littleEndian
        return withUnsafeBytes(of: &littleEndianBytes, { Data($0) })
    }
}
