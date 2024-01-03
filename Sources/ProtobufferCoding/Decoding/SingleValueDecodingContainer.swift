//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO
import Foundation


/// A single-value decoding container, which supports decoding a single unkeyed value.
struct ProtobufferSingleValueDecodingContainer: SingleValueDecodingContainer {
    let codingPath: [any CodingKey]
    private let buffer: ByteBuffer
    
    /// The buffer should point to the start of a value
    init(codingPath: [any CodingKey], buffer: ByteBuffer) {
        self.codingPath = codingPath
        self.buffer = buffer
    }
    
    
    func decodeNil() -> Bool {
        fatalError("Not implemented.")
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        if let value = buffer.getInteger(at: buffer.readerIndex, endianness: .little, as: UInt8.self) {
            return value == 1
        } else {
            return false
        }
    }
    
    func decode(_ type: String.Type) throws -> String {
        // NOTE normally, we'd return empty strings in case a field is not present.
        // That doesn't apply, though, in this case, since the SingleValueDecoder only ever gets used
        // in cases where we already have data and just need to pipe it through e.g. a String's `init(from:)`.
        // (At least, that's how it is intended to be used. Anything else is UB.)
        
        // This is somewhat annoying but basically the thing is that bc we don't have any field info we'll just have to make a guess that this is in fact a string and that the first byte is the varInt length
        var bufferCopy = buffer
        let length = Int(try bufferCopy.readVarInt())
        return try buffer.decodeProtoString(
            fieldValueInfo: .lengthDelimited(dataLength: length, dataOffset: bufferCopy.readerIndex - buffer.readerIndex),
            fieldValueOffset: buffer.readerIndex,
            codingPath: codingPath,
            makeDataCorruptedError: { errorDesc in
                DecodingError.dataCorruptedError(in: self, debugDescription: errorDesc)
            }
        )
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        try buffer.getProtoDouble(at: buffer.readerIndex)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        try buffer.getProtoFloat(at: buffer.readerIndex)
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        try decodeVarInt(type)
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        try throwUnsupportedNumericTypeDecodingError(type, codingPath: codingPath)
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        try throwUnsupportedNumericTypeDecodingError(type, codingPath: codingPath)
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        try decodeVarInt(type)
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        try decodeVarInt(type)
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        try decodeVarInt(type)
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try throwUnsupportedNumericTypeDecodingError(type, codingPath: codingPath)
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try throwUnsupportedNumericTypeDecodingError(type, codingPath: codingPath)
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try decodeVarInt(type)
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try decodeVarInt(type)
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        fatalError("Not implemented (type: \(type))")
    }
    
    
    private func decodeVarInt<T: BinaryInteger>(_: T.Type) throws -> T {
        T(truncatingIfNeeded: try buffer.getVarInt(at: buffer.readerIndex))
    }
}
