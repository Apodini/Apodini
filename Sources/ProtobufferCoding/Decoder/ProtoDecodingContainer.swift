//
//  ProtoDecodingContainer.swift
//
//
//  Created by Moritz Schüll on 28.11.20.
//
//  The decoding logic here was created with
//  https://github.com/apple/swift-protobuf/blob/master/Sources/SwiftProtobuf/BinaryDecoder.swift
//  as a reference.
//  Thus, there are several similarities and also parts simply copied.
//

import Foundation

/// Offers basic functionality shared by several decoding containers for Protobuffers.
internal class InternalProtoDecodingContainer {
    var codingPath: [CodingKey]
    /// The strategy that this container uses to encode `Int`s and `UInt`s.
    ///
    /// Set to `nil` (default) to use the architectures bit width.
    var variableWidthIntegerStrategy: VariableWidthIntegerStrategy

    internal init(codingPath: [CodingKey] = [], variableWidthIntegerStrategy: VariableWidthIntegerStrategy) {
        self.codingPath = codingPath
        self.variableWidthIntegerStrategy = variableWidthIntegerStrategy
    }

    /// Taken from SwiftProtobuf:
    /// https://github.com/apple/swift-protobuf/blob/master/Sources/SwiftProtobuf/BinaryDecoder.swift
    private func decodeFourByteNumber<T>(from data: Data, into output: inout T) throws {
        data.withUnsafeBytes { rawBufferPointer in
            if let dataRawPtr = rawBufferPointer.baseAddress {
                withUnsafeMutableBytes(of: &output) { dest -> Void in
                    dest.copyMemory(from: UnsafeRawBufferPointer(start: dataRawPtr, count: 4))
                }
            }
        }
    }

    /// Taken from SwiftProtobuf:
    /// https://github.com/apple/swift-protobuf/blob/master/Sources/SwiftProtobuf/BinaryDecoder.swift
    private func decodeEightByteNumber<T>(from data: Data, into output: inout T) throws {
        data.withUnsafeBytes { rawBufferPointer in
            if let dataRawPtr = rawBufferPointer.baseAddress {
                withUnsafeMutableBytes(of: &output) { dest -> Void in
                    dest.copyMemory(from: UnsafeRawBufferPointer(start: dataRawPtr, count: 8))
                }
            }
        }
    }

    internal func decodeDouble(_ data: Data) throws -> Double {
        var littleEndianBytes: UInt64 = 0
        try decodeEightByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt64(littleEndian: littleEndianBytes)
        var double: Double = 0
        let size = MemoryLayout<Double>.size
        memcpy(&double, &nativeEndianBytes, size)
        return double
    }

    internal func decodeFloat(_ data: Data) throws -> Float {
        var littleEndianBytes: UInt32 = 0
        try decodeFourByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt32(littleEndian: littleEndianBytes)
        var float: Float = 0
        let size = MemoryLayout<Float>.size
        memcpy(&float, &nativeEndianBytes, size)
        return float
    }

    internal func decodeInt32(_ data: Data) throws -> Int32 {
        var littleEndianBytes: UInt32 = 0
        try decodeFourByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt32(littleEndian: littleEndianBytes)
        var int32: Int32 = 0
        let size = MemoryLayout<Int32>.size
        memcpy(&int32, &nativeEndianBytes, size)
        return int32
    }

    internal func decodeInt64(_ data: Data) throws -> Int64 {
        var littleEndianBytes: UInt64 = 0
        try decodeEightByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt64(littleEndian: littleEndianBytes)
        var int64: Int64 = 0
        let size = MemoryLayout<Int64>.size
        memcpy(&int64, &nativeEndianBytes, size)
        return int64
    }

    internal func decodeUInt32(_ data: Data) throws -> UInt32 {
        var littleEndianBytes: UInt32 = 0
        try decodeFourByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt32(littleEndian: littleEndianBytes)
        var uint32: UInt32 = 0
        let size = MemoryLayout<UInt32>.size
        memcpy(&uint32, &nativeEndianBytes, size)
        return uint32
    }

    internal func decodeUInt64(_ data: Data) throws -> UInt64 {
        var littleEndianBytes: UInt64 = 0
        try decodeEightByteNumber(from: data, into: &littleEndianBytes)
        var nativeEndianBytes = UInt64(littleEndian: littleEndianBytes)
        var uint64: UInt64 = 0
        let size = MemoryLayout<UInt64>.size
        memcpy(&uint64, &nativeEndianBytes, size)
        return uint64
    }

    internal func decodeRepeatedBool(_ data: Data) throws -> [Bool] {
        var output: [Bool] = []
        var offset = 0
        while offset < data.count {
            // floats are fixed 1 byte in length
            let number = data[offset ..< (offset + 1)]
            if number.first != 0 {
                output.append(true)
            } else {
                output.append(false)
            }
            offset += 1
        }
        return output
    }

    internal func decodeRepeatedFloat(_ data: Data) throws -> [Float] {
        var output: [Float] = []
        var offset = 0
        while offset < data.count {
            // floats are fixed 32 bit in length
            let number = data[offset ..< (offset + 4)]
            output.append(try decodeFloat(number))
            offset += 4
        }
        return output
    }

    internal func decodeRepeatedDouble(_ data: Data) throws -> [Double] {
        var output: [Double] = []
        var offset = 0
        while offset < data.count {
            // floats are fixed 64 bit in length
            let number = data[offset ..< (offset + 8)]
            output.append(try decodeDouble(number))
            offset += 8
        }
        return output
    }

    internal func decodeRepeatedInt32(_ data: Data) throws -> [Int32] {
        var output: [Int32] = []
        var offset = 0
        while offset < data.count {
            // int32 are encoded as VarInts
            let (number, newOffset) = try VarInt.decode(data, offset: offset)
            output.append(try decodeInt32(number))
            offset = newOffset
        }
        return output
    }

    internal func decodeRepeatedInt64(_ data: Data) throws -> [Int64] {
        var output: [Int64] = []
        var offset = 0
        while offset < data.count {
            // int64 are encoded as VarInts
            let (number, newOffset) = try VarInt.decode(data, offset: offset)
            output.append(try decodeInt64(number))
            offset = newOffset
        }
        return output
    }

    internal func decodeRepeatedUInt32(_ data: Data) throws -> [UInt32] {
        var output: [UInt32] = []
        var offset = 0
        while offset < data.count {
            // uint32 are encoded as VarInts
            let (number, newOffset) = try VarInt.decode(data, offset: offset)
            output.append(try decodeUInt32(number))
            offset = newOffset
        }
        return output
    }

    internal func decodeRepeatedUInt64(_ data: Data) throws -> [UInt64] {
        var output: [UInt64] = []
        var offset = 0
        while offset < data.count {
            // uint64 are encoded as VarInts
            let (number, newOffset) = try VarInt.decode(data, offset: offset)
            output.append(try decodeUInt64(number))
            offset = newOffset
        }
        return output
    }

    internal func decodeRepeatedString(_ data: [Data]) -> [String] {
        var output: [String] = []
        for value in data {
            if let strValue = String(data: value, encoding: .utf8) {
                output.append(strValue)
            }
        }
        return output
    }
}

// MARK: - Type extensions
internal extension Int {
    init(from value: Data?, using container: InternalProtoDecodingContainer) throws {
        guard let value = value else {
            throw ProtoError.decodingError("No data to initialize from")
        }
        if container.variableWidthIntegerStrategy == .thirtyTwo {
            try self.init(container.decodeInt32(value))
        } else if container.variableWidthIntegerStrategy == .sixtyFour {
            try self.init(container.decodeInt64(value))
        } else {
            throw ProtoError.decodingError("Unknown width of Int type")
        }
    }
}

internal extension UInt {
    init(from value: Data?, using container: InternalProtoDecodingContainer) throws {
        guard let value = value else {
            throw ProtoError.decodingError("No data to initialize from")
        }
        if container.variableWidthIntegerStrategy == .thirtyTwo {
            try self.init(container.decodeUInt32(value))
        } else if container.variableWidthIntegerStrategy == .sixtyFour {
            try self.init(container.decodeUInt64(value))
        } else {
            throw ProtoError.decodingError("Unknown width of UInt type")
        }
    }
}

internal extension Array where Element == Int {
    init(from value: Data?, using container: InternalProtoDecodingContainer) throws {
        guard let value = value else {
            throw ProtoError.decodingError("No data to initialize from")
        }
        self.init()
        if container.variableWidthIntegerStrategy == .thirtyTwo {
            try container.decodeRepeatedInt32(value).forEach { self.append(Int($0)) }
        } else if container.variableWidthIntegerStrategy == .sixtyFour {
            try container.decodeRepeatedInt64(value).forEach { self.append(Int($0)) }
        }
    }
}

internal extension Array where Element == UInt {
    init(from value: Data?, using container: InternalProtoDecodingContainer) throws {
        guard let value = value else {
            throw ProtoError.decodingError("No data to initialize from")
        }
        self.init()
        if container.variableWidthIntegerStrategy == .thirtyTwo {
            try container.decodeRepeatedUInt32(value).forEach { self.append(UInt($0)) }
        } else if container.variableWidthIntegerStrategy == .sixtyFour {
            try container.decodeRepeatedUInt64(value).forEach { self.append(UInt($0)) }
        }
    }
}
