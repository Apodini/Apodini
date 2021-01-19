//
//  SingleValueProtoEncodingContainer.swift
//  
//
//  Created by Moritz Schüll on 23.12.20.
//

import Foundation

private struct Wrapper<T: Encodable>: Encodable {
    var value: T
}

class SingleValueProtoEncodingContainer: InternalProtoEncodingContainer, SingleValueEncodingContainer {
    private let fieldNumber: Int

    override init(using encoder: InternalProtoEncoder, codingPath: [CodingKey]) {
        self.fieldNumber = 1
        super.init(using: encoder, codingPath: codingPath)
    }

    init(using encoder: InternalProtoEncoder, codingPath: [CodingKey], fieldNumber: Int) {
        self.fieldNumber = fieldNumber
        super.init(using: encoder, codingPath: codingPath)
    }

    func encodeNil() throws {
        // nothing to do
    }

    func encode(_ value: Bool) throws {
        try encodeBool(value, tag: fieldNumber)
    }

    func encode(_ value: String) throws {
        try encodeString(value, tag: fieldNumber)
    }

    func encode(_ value: Double) throws {
        try encodeDouble(value, tag: fieldNumber)
    }

    func encode(_ value: Float) throws {
        try encodeFloat(value, tag: fieldNumber)
    }

    func encode(_ value: Int) throws {
        if MemoryLayout<Int>.size == 32 {
            try encodeInt32(Int32(value), tag: fieldNumber)
        } else if MemoryLayout<Int>.size == 64 {
            try encodeInt64(Int64(value), tag: fieldNumber)
        }
    }

    func encode(_ value: Int8) throws {
        throw ProtoError.encodingError("Int8 not supported, use Int32 or Int64")
    }

    func encode(_ value: Int16) throws {
        throw ProtoError.encodingError("Int16 not supported, use Int32 or Int64")
    }

    func encode(_ value: Int32) throws {
        try encodeInt32(value, tag: fieldNumber)
    }

    func encode(_ value: Int64) throws {
        try encodeInt64(value, tag: fieldNumber)
    }

    func encode(_ value: UInt) throws {
        if MemoryLayout<UInt>.size == 32 {
            try encodeUInt32(UInt32(value), tag: fieldNumber)
        } else if MemoryLayout<UInt>.size == 64 {
            try encodeUInt64(UInt64(value), tag: fieldNumber)
        }
    }

    func encode(_ value: UInt8) throws {
        throw ProtoError.encodingError("UInt8 not supported, use UInt32 or UInt64")
    }

    func encode(_ value: UInt16) throws {
        throw ProtoError.encodingError("UInt16 not supported, use UInt32 or UInt64")
    }

    func encode(_ value: UInt32) throws {
        try encodeUInt32(value, tag: fieldNumber)
    }

    func encode(_ value: UInt64) throws {
        try encodeUInt64(value, tag: fieldNumber)
    }

    func encode(_ values: [Bool]) throws {
        try encodeRepeatedBool(values, tag: fieldNumber)
    }

    func encode(_ values: [Double]) throws {
        try encodeRepeatedDouble(values, tag: fieldNumber)
    }

    func encode(_ values: [Float]) throws {
        try encodeRepeatedFloat(values, tag: fieldNumber)
    }

    func encode(_ values: [Int]) throws {
        if MemoryLayout<Int>.size == 32 {
            try encodeRepeatedInt32(values.compactMap { Int32($0) }, tag: fieldNumber)
        } else if MemoryLayout<Int>.size == 64 {
            try encodeRepeatedInt64(values.compactMap { Int64($0) }, tag: fieldNumber)
        }
    }

    func encode(_ values: [Int32]) throws {
        try encodeRepeatedInt32(values, tag: fieldNumber)
    }

    func encode(_ values: [Int64]) throws {
        try encodeRepeatedInt64(values, tag: fieldNumber)
    }

    func encode(_ values: [UInt]) throws {
        if MemoryLayout<UInt>.size == 32 {
            try encodeRepeatedUInt32(values.compactMap { UInt32($0) }, tag: fieldNumber)
        } else if MemoryLayout<UInt>.size == 64 {
            try encodeRepeatedUInt64(values.compactMap { UInt64($0) }, tag: fieldNumber)
        }
    }

    func encode(_ values: [UInt32]) throws {
        try encodeRepeatedUInt32(values, tag: fieldNumber)
    }

    func encode(_ values: [UInt64]) throws {
        try encodeRepeatedUInt64(values, tag: fieldNumber)
    }

    func encode(_ values: [Data]) throws {
        try encodeRepeatedData(values, tag: fieldNumber)
    }

    func encode(_ values: [String]) throws {
        try encodeRepeatedString(values, tag: fieldNumber)
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        // adds support for arrays of primitive types
        // by type matching (since they are not part
        // of the SingleValueEncodingContainer protocol)
        if T.self == Data.self, let value = value as? Data {
            // simply a byte array
            // prepend an extra byte containing the length
            var length = Data([UInt8(value.count)])
            length.append(value)
            appendData(length, tag: fieldNumber, wireType: .lengthDelimited)
        } else if isPrimitiveSupportedArray(T.self) {
            try encodeArray(value)
        } else if isOptional(T.self) {
            try encodeOptional(value, tag: fieldNumber)
        } else if isPrimitiveSupported(T.self) {
            try encodePrimitive(value)
        } else if [
                    Int8.self, Int16.self,
                    UInt8.self, UInt16.self,
                    [Int].self, [Int8].self, [Int16].self,
                    [UInt].self, [UInt8].self, [UInt16].self
        ].contains(where: { $0 == T.self }) {
            throw ProtoError.decodingError("Encoding values of type \(T.self) is not supported yet")
        } else {
            throw ProtoError.encodingError("Single value encoding only supported for (repeated) primitive data types")
        }
    }

    private func encodePrimitive<T>(_ value: T) throws where T: Encodable {
        if T.self == String.self, let value = value as? String {
            try encode(value)
        } else if T.self == Bool.self, let value = value as? Bool {
            try encode(value)
        } else if T.self == Int.self, let value = value as? Int {
            try encode(value)
        } else if T.self == Int32.self, let value = value as? Int32 {
            try encode(value)
        } else if T.self == Int64.self, let value = value as? Int64 {
            try encode(value)
        } else if T.self == UInt.self, let value = value as? UInt {
            try encode(value)
        } else if T.self == UInt32.self, let value = value as? UInt32 {
            try encode(value)
        } else if T.self == UInt64.self, let value = value as? UInt64 {
            try encode(value)
        } else if T.self == Double.self, let value = value as? Double {
            try encode(value)
        } else if T.self == Float.self, let value = value as? Float {
            try encode(value)
        }
    }

    // swiftlint:disable cyclomatic_complexity
    private func encodeArray<T>(_ value: T) throws where T: Encodable {
        if T.self == [Bool].self, let value = value as? [Bool] {
            try encode(value)
        } else if T.self == [Float].self, let value = value as? [Float] {
            try encode(value)
        } else if T.self == [Double].self, let value = value as? [Double] {
            try encode(value)
        } else if T.self == [Int].self, let value = value as? [Int] {
            try encode(value)
        } else if T.self == [Int32].self, let value = value as? [Int32] {
            try encode(value)
        } else if T.self == [Int64].self, let value = value as? [Int64] {
            try encode(value)
        } else if T.self == [UInt].self, let value = value as? [UInt] {
            try encode(value)
        } else if T.self == [UInt32].self, let value = value as? [UInt32] {
            try encode(value)
        } else if T.self == [UInt64].self, let value = value as? [UInt64] {
            try encode(value)
        } else if T.self == [Data].self, let value = value as? [Data] {
            try encode(value)
        } else if T.self == [String].self, let value = value as? [String] {
            try encode(value)
        } else if T.self == [Bool?].self, let value = value as? [Bool?] {
            try encode(value.compactMap { $0 })
        } else if T.self == [Float?].self, let value = value as? [Float?] {
            try encode(value.compactMap { $0 })
        } else if T.self == [Double?].self, let value = value as? [Double?] {
            try encode(value.compactMap { $0 })
        } else if T.self == [Int?].self, let value = value as? [Int?] {
            try encode(value.compactMap { $0 })
        } else if T.self == [Int32?].self, let value = value as? [Int32?] {
            try encode(value.compactMap { $0 })
        } else if T.self == [Int64?].self, let value = value as? [Int64?] {
            try encode(value.compactMap { $0 })
        } else if T.self == [UInt?].self, let value = value as? [UInt?] {
            try encode(value.compactMap { $0 })
        } else if T.self == [UInt32?].self, let value = value as? [UInt32?] {
            try encode(value.compactMap { $0 })
        } else if T.self == [UInt64?].self, let value = value as? [UInt64?] {
            try encode(value.compactMap { $0 })
        } else if T.self == [Data?].self, let value = value as? [Data?] {
            try encode(value.compactMap { $0 })
        } else if T.self == [String?].self, let value = value as? [String?] {
            try encode(value.compactMap { $0 })
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
