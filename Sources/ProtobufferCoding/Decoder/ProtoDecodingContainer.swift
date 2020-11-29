//
//  ProtoDecodingContainer.swift
//  
//
//  Created by Moritz Schüll on 28.11.20.
//

import Foundation


/// Offers basic functionality shared by several decoding containers for Protobuffers.
internal class InternalProtoDecodingContainer {
    var codingPath: [CodingKey]


    public init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
    }

    // Taken from SwiftProtobuf: https://github.com/apple/swift-protobuf/blob/master/Sources/SwiftProtobuf/BinaryDecoder.swift
    private func decodeFourByteNumber<T>(from data: Data, into output: inout T) throws {
        data.withUnsafeBytes { rawBufferPointer in
            let dataRawPtr = rawBufferPointer.baseAddress!
            withUnsafeMutableBytes(of: &output) { dest -> Void in
                dest.copyMemory(from: UnsafeRawBufferPointer(start: dataRawPtr, count: 4))
            }
        }
    }

    // Taken from SwiftProtobuf: https://github.com/apple/swift-protobuf/blob/master/Sources/SwiftProtobuf/BinaryDecoder.swift
    private func decodeEightByteNumber<T>(from data: Data, into output: inout T) throws {
        data.withUnsafeBytes { rawBufferPointer in
            let dataRawPtr = rawBufferPointer.baseAddress!
            withUnsafeMutableBytes(of: &output) { dest -> Void in
                dest.copyMemory(from: UnsafeRawBufferPointer(start: dataRawPtr, count: 8))
            }
        }
    }

    public func decodeDouble(_ data: Data) throws -> Double {
        var littleEndianBytes: UInt64 = 0
        try decodeEightByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt64(littleEndian: littleEndianBytes)
        var double: Double = 0
        let size = MemoryLayout<Double>.size
        memcpy(&double, &nativeEndianBytes, size)
        return double
    }

    public func decodeFloat(_ data: Data) throws -> Float {
        var littleEndianBytes: UInt32 = 0
        try decodeFourByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt32(littleEndian: littleEndianBytes)
        var float: Float = 0
        let size = MemoryLayout<Float>.size
        memcpy(&float, &nativeEndianBytes, size)
        return float
    }

    public func decodeInt32(_ data: Data) throws -> Int32 {
        var littleEndianBytes: UInt32 = 0
        try decodeFourByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt32(littleEndian: littleEndianBytes)
        var int32: Int32 = 0
        let size = MemoryLayout<Int32>.size
        memcpy(&int32, &nativeEndianBytes, size)
        return int32
    }

    public func decodeInt64(_ data: Data) throws -> Int64 {
        var littleEndianBytes: UInt64 = 0
        try decodeEightByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt64(littleEndian: littleEndianBytes)
        var int64: Int64 = 0
        let size = MemoryLayout<Int64>.size
        memcpy(&int64, &nativeEndianBytes, size)
        return int64
    }

    public func decodeUInt32(_ data: Data) throws -> UInt32 {
        var littleEndianBytes: UInt32 = 0
        try decodeFourByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt32(littleEndian: littleEndianBytes)
        var uint32: UInt32 = 0
        let size = MemoryLayout<UInt32>.size
        memcpy(&uint32, &nativeEndianBytes, size)
        return uint32
    }

    public func decodeUInt64(_ data: Data) throws -> UInt64 {
        var littleEndianBytes: UInt64 = 0
        try decodeEightByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt64(littleEndian: littleEndianBytes)
        var uint64: UInt64 = 0
        let size = MemoryLayout<UInt64>.size
        memcpy(&uint64, &nativeEndianBytes, size)
        return uint64
    }
}
