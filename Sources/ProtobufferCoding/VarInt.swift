//
//  VarInt.swift
//  
//
//  Created by Moritz Schüll on 01.12.20.
//

import Foundation

/// Uitily that offers VarInt decoding functions
enum VarInt {
    /// Returns the Data that belongs to the VarInt (without the run-length encoding bits)
    /// and the index of the first byte after the VarInt
    static func decode(_ data: Data, offset: Int) throws -> (Data, Int) {
        var varInt = Int64()

        var currentIndex = offset
        var hasNext = 0
        var count = 0
        repeat {
            if currentIndex >= data.count {
                throw ProtobufferError.decodingError("Not enough data left to decode VarInt properly")
            }
            let byte = data[currentIndex]

            // we need to drop the most significant bit of byte, and
            // append byte to beginning of varint (varints come in reversed order)
            varInt = (Int64(byte & 0b01111111) << (7 * count)) | varInt

            // if most significant bit is set, we need to continue with another byte
            hasNext = Int(byte & 0b10000000)
            currentIndex += 1
            count += 1
        } while (hasNext > 0)

        return (Data(bytes: &varInt, count: MemoryLayout.size(ofValue: varInt)),
                currentIndex)
    }

    /// Returns:
    ///     1. Int: the decoded VarInt
    ///     2. Int: the index of the first byte after the decoded VarInt
    static func decodeToInt(_ data: Data, offset: Int) throws -> (Int, Int) {
        let (varInt, newOffset) = try decode(data, offset: offset)

        var littleEndianBytes: UInt64 = 0
        varInt.withUnsafeBytes { rawBufferPointer in
            if let dataRawPtr = rawBufferPointer.baseAddress {
                withUnsafeMutableBytes(of: &littleEndianBytes) { dest -> Void in
                    dest.copyMemory(from: UnsafeRawBufferPointer(start: dataRawPtr, count: 8))
                }
            }
        }
        var nativeEndianBytes = UInt64(littleEndian: littleEndianBytes)
        var int: Int = 0
        let size = MemoryLayout<Int>.size
        memcpy(&int, &nativeEndianBytes, size)
        return (int, newOffset)
    }
}
