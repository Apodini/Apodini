//
//  UnkeyedProtoDecodingContainer.swift
//
//
//  Created by Moritz Schüll on 20.11.20.
//

import Foundation

class UnkeyedProtoDecodingContainer: InternalProtoDecodingContainer, UnkeyedDecodingContainer {
    var currentIndex: Int
    var values: [[Data]]
    let referencedBy: Data?

    var count: Int? {
        values.count
    }

    var isAtEnd: Bool {
        currentIndex >= values.count
    }

    init(from data: [[Data]],
         codingPath: [CodingKey] = [],
         variableWidthIntegerCodingStrategy: VariableWidthIntegerCodingStrategy,
         referencedBy: Data? = nil) {
        self.currentIndex = 0
        self.values = data
        self.referencedBy = referencedBy

        super.init(codingPath: codingPath, variableWidthIntegerCodingStrategy: variableWidthIntegerCodingStrategy)
    }

    private func popNext() -> [Data] {
        if !isAtEnd {
            let data = values[currentIndex]
            currentIndex += 1
            return data
        }

        print("No more data to decode")
        return []
    }

    func decodeNil() throws -> Bool {
        false
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        if let value = popNext().last,
           value.first != 0 {
            return true
        }
        return false
    }

    func decode(_ type: String.Type) throws -> String {
        if let value = popNext().last,
           let strValue = String(data: value, encoding: .utf8) {
            return strValue
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Data.Type) throws -> Data {
        if let value = popNext().last {
            return value
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Double.Type) throws -> Double {
        if let value = popNext().last {
            return try decodeDouble(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Float.Type) throws -> Float {
        if let value = popNext().last {
            return try decodeFloat(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Int.Type) throws -> Int {
        try Int(from: popNext().last, using: self)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        throw ProtoError.decodingError("Int8 not supported, use Int32 or Int64")
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        throw ProtoError.decodingError("Int16 not supported, use Int32 or Int64")
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        if let value = popNext().last {
            return try decodeInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        if let value = popNext().last {
            return try decodeInt64(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        try UInt(from: popNext().last, using: self)
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        throw ProtoError.decodingError("UInt8 not supported, use UInt32 or UInt64")
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        throw ProtoError.decodingError("UInt16 not supported, use UInt32 or UInt64")
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        if let value = popNext().last {
            return try decodeUInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        if let value = popNext().last {
            return try decodeUInt64(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Bool].Type) throws -> [Bool] {
        if let value = popNext().last {
            return try decodeRepeatedBool(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Float].Type) throws -> [Float] {
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = popNext().last {
            return try decodeRepeatedFloat(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Double].Type) throws -> [Double] {
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = popNext().last {
            return try decodeRepeatedDouble(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Int].Type) throws -> [Int] {
        try [Int](from: popNext().last, using: self)
    }

    func decode(_ type: [Int32].Type) throws -> [Int32] {
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = popNext().last {
            return try decodeRepeatedInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Int64].Type) throws -> [Int64] {
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = popNext().last {
            return try decodeRepeatedInt64(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [UInt].Type) throws -> [UInt] {
        try [UInt](from: popNext().last, using: self)
    }

    func decode(_ type: [UInt32].Type) throws -> [UInt32] {
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = popNext().last {
            return try decodeRepeatedUInt32(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [UInt64].Type) throws -> [UInt64] {
        // as of Proto3, repeated values of scalar numeric types are always encoded as packed
        // thus, there will only be one value for the given key,
        // containing n number
        if let value = popNext().last {
            return try decodeRepeatedUInt64(value)
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decode(_ type: [Data].Type) throws -> [Data] {
        let values = popNext()
        // the data is already [Data] :D
        return values
    }

    func decode(_ type: [String].Type) throws -> [String] {
        let values = popNext()
        return decodeRepeatedString(values)
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        // we need to switch here to also be able to decode structs with generic types
        // if struct has generic type, this will always end up here
        if isPrimitiveSupported(type) {
            return try decodePrimitive(type)
        } else if isPrimitiveSupportedArray(type) {
            return try decodeArray(type)
        } else if [
                    Int8.self, Int16.self,
                    UInt8.self, UInt16.self,
                    [Int8].self, [Int16].self,
                    [UInt8].self, [UInt16].self
        ].contains(where: { $0 == T.self }) {
            throw ProtoError.decodingError("Decoding values of type \(T.self) is not supported yet")
        } else {
            // we encountered a nested structure
            if let value = popNext().last {
                return try ProtobufferDecoder().decode(type, from: value)
            }
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws
    -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        if let value = popNext().last {
            return try InternalProtoDecoder(from: value, with: variableWidthIntegerCodingStrategy).container(keyedBy: type)
        }
        throw ProtoError.unsupportedDataType("nestedContainer not available")
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        if let value = popNext().last {
            return try InternalProtoDecoder(from: value, with: variableWidthIntegerCodingStrategy).unkeyedContainer()
        }
        throw ProtoError.unsupportedDataType("nestedUnkeyedContainer not available")
    }

    func superDecoder() throws -> Decoder {
        if let referencedBy = referencedBy {
            return InternalProtoDecoder(from: referencedBy, with: variableWidthIntegerCodingStrategy)
        }
        throw ProtoError.unsupportedDecodingStrategy("Cannot decode super")
    }
}

// MARK: - Type switching
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable discouraged_optional_boolean
extension  UnkeyedProtoDecodingContainer {
    func decodePrimitive<T>(_ type: T.Type) throws -> T where T: Decodable {
        if T.self == Data.self || T.self == Data?.self,
           let value = try decode(Data.self) as? T {
            return value
        } else if T.self == String.self || T.self == String?.self,
                  let value = try decode(String.self) as? T {
            return value
        } else if T.self == Bool.self || T.self == Bool?.self,
                  let value = try decode(Bool.self) as? T {
            return value
        } else if T.self == Int.self || T.self == Int?.self,
                  let value = try decode(Int.self) as? T {
            return value
        } else if T.self == Int32.self || T.self == Int32?.self,
                  let value = try decode(Int32.self) as? T {
            return value
        } else if T.self == Int64.self || T.self == Int64?.self,
                  let value = try decode(Int64.self) as? T {
            return value
        } else if T.self == UInt.self || T.self == UInt?.self,
                  let value = try decode(UInt.self) as? T {
            return value
        } else if T.self == UInt32.self || T.self == UInt32?.self,
                  let value = try decode(UInt32.self) as? T {
            return value
        } else if T.self == UInt64.self || T.self == UInt64?.self,
                  let value = try decode(UInt64.self) as? T {
            return value
        } else if T.self == Double.self || T.self == Double?.self,
                  let value = try decode(Double.self) as? T {
            return value
        } else if T.self == Float.self || T.self == Float?.self,
                  let value = try decode(Float.self) as? T {
            return value
        }
        throw ProtoError.decodingError("No data for given key")
    }

    func decodeArray<T>(_ type: T.Type) throws -> T where T: Decodable {
        if T.self == [Bool].self || T.self == [Bool?].self,
           let value = try decode([Bool].self) as? T {
            return value
        } else if T.self == [Float].self || T.self == [Float?].self,
                  let value = try decode([Float].self) as? T {
            return value
        } else if T.self == [Double].self || T.self == [Double?].self,
                  let value = try decode([Double].self) as? T {
            return value
        } else if T.self == [Int].self || T.self == [Int?].self,
                  let value = try decode([Int].self) as? T {
            return value
        } else if T.self == [Int32].self || T.self == [Int32?].self,
                  let value = try decode([Int32].self) as? T {
            return value
        } else if T.self == [Int64].self || T.self == [Int64?].self,
                  let value = try decode([Int64].self) as? T {
            return value
        } else if T.self == [UInt].self || T.self == [UInt?].self,
                  let value = try decode([UInt].self) as? T {
            return value
        } else if T.self == [UInt32].self || T.self == [UInt32?].self,
                  let value = try decode([UInt32].self) as? T {
            return value
        } else if T.self == [UInt64].self || T.self == [UInt64?].self,
                  let value = try decode([UInt64].self) as? T {
            return value
        } else if T.self == [String].self || T.self == [String?].self,
                  let value = try decode([String].self) as? T {
            return value
        } else if T.self == [Data].self || T.self == [Data?].self,
                  let value = try decode([Data].self) as? T {
            return value
        }
        throw ProtoError.decodingError("No data for given key")
    }
}
// swiftlint:enable cyclomatic_complexity
