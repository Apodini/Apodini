//
//  VarInt.swift
//  
//
//  Created by Moritz Schüll on 01.12.20.
//

import Foundation


/// Uitily class that offers VarInt decoding functions
class VarInt {

    /// Returns the Data that belongs to the VarInt (without the run-length encoding bits)
    /// and the index of the first byte after the VarInt
    public static func decode(_ data: Data, offset: Int) throws -> (Data, Int) {
        var varInt = Int64()

        var currentIndex = offset
        var hasNext = 0
        var count = 0
        repeat {
            if currentIndex >= data.count {
                throw ProtoError.decodingError("Not enough data left to decode VarInt properly")
            }
            let byte = data[currentIndex]

            // we need to drop the most significant bit of byte, and
            // append byte to beginning of varint (varints come in reversed order)
            varInt = (Int64(byte & 0b01111111) << (7*count)) | varInt

            // if most significant bit is set, we need to continue with another byte
            hasNext = Int(byte & 0b10000000)
            currentIndex += 1
            count += 1
        } while (hasNext > 0)

        return (Data(bytes: &varInt, count: MemoryLayout.size(ofValue: varInt)),
                currentIndex)
    }
}
