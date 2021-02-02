//
//  ProtobufferDecoder.swift
//
//
//  Created by Moritz Schüll on 18.11.20.
//

import Foundation

internal class InternalProtoDecoder: Decoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]

    let data: Data
    // Building two data structures here:
    //  - dictionary: for the keyed container (to have fast access via key)
    //  - entries: for the unkeyed container (to preserve order, which dictionary does not)
    var dictionary: [Int: [Data]]
    var entries: [[Data]]
    // helper to keep track of which key is placed at which index in entries
    // only needed for build-up of entries (to ensure all values with same key end up at same index)
    var keyIndices: [Int: Int]

    /// The strategy that this encoder uses to encode `Int`s and `UInt`s.
    var integerWidthCodingStrategy: IntegerWidthCodingStrategy

    init(from data: Data, with integerWidthCodingStrategy: IntegerWidthCodingStrategy) {
        self.data = data
        self.integerWidthCodingStrategy = integerWidthCodingStrategy
        dictionary = [:]
        entries = []
        keyIndices = [:]
        codingPath = []
        userInfo = [:]

        decode(from: data)
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(
            KeyedProtoDecodingContainer(from: self.dictionary, integerWidthCodingStrategy: integerWidthCodingStrategy)
        )
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        UnkeyedProtoDecodingContainer(from: entries, codingPath: codingPath, integerWidthCodingStrategy: integerWidthCodingStrategy)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw ProtoError.unsupportedDecodingStrategy("Single value decoding not supported")
    }

    func decode(from: Data) {
        dictionary = [Int: [Data]]()
        entries = []

        // points to the byte we want to read next
        var readIndex = 0
        // jump over any leading zero-bytes
        while readIndex < from.count,
              from[readIndex] == UInt8(0) {
            readIndex += 1
        }
        // start reading the non-zero bytes
        while readIndex < from.count {
            // byte contains: 5 bits of field tag, 3 bits of field data type
            let byte = from[readIndex]
            let fieldTag = Int(byte >> 3) // shift "out" last 3 bytes
            let fieldType = Int(byte & 0b00000111) // only keep last 3 bytes

            do {
                // find the field in T with the according CodingKey to the fieldTag
                let (value, newIndex) = try readField(from: from,
                                                      fieldTag: fieldTag,
                                                      fieldType: fieldType,
                                                      fieldStartIndex: readIndex + 1)

                // set cursor forward to the next field tag
                readIndex = newIndex
                if dictionary[fieldTag] == nil {
                    dictionary[fieldTag] = [value]
                    keyIndices[fieldTag] = entries.count
                    entries.append([value])
                } else if let index = keyIndices[fieldTag] {
                    dictionary[fieldTag]?.append(value)
                    entries[index].append(value)
                }
            } catch {
                print("Unable to decode field with tag=\(fieldTag) and type=\(fieldType). Stop decoding.")
                return
            }
        }
    }

    private func readLengthDelimited(from data: Data, fieldStartIndex: Int) throws -> (Data, Int) {
        // the first VarInt contains the length of the value
        let (length, _) = try VarInt.decodeToInt(data, offset: fieldStartIndex)
        // assure we have enough bytes left to read
        if data.count - (fieldStartIndex + 1) < length {
            throw ProtoError.decodingError("Not enough data left to code length-delimited value")
        }
        // here we make a copy, since the data here might be a nested data structure
        // this ensures the copy's byte indexing starts with 0 in the case the ProtoDecoder is invoked on it again
        let byteValue = data.subdata(in: (fieldStartIndex + 1) ..< (fieldStartIndex + length + 1))
        return (byteValue, fieldStartIndex + length + 1)
    }

    // Function reads the value of a field from data, starting at byte-index fieldStartIndex.
    // The length of the read data depends on the field-type.
    // The function returns the value, and the starting index of the next field tag.
    private func readField(from data: Data, fieldTag: Int, fieldType: Int, fieldStartIndex: Int) throws -> (Data, Int) {
        guard let wireType = WireType(rawValue: fieldType) else {
            throw ProtoError.unknownType(fieldType)
        }

        switch wireType {
        case WireType.varInt:
            return try VarInt.decode(data, offset: fieldStartIndex)

        case WireType.bit64:
            if fieldStartIndex + 7 >= data.count {
                throw ProtoError.decodingError("Not enough data left to read 64-bit value")
            }
            let byteValue = data[fieldStartIndex ... (fieldStartIndex + 7)]
            return (byteValue, fieldStartIndex + 8)

        case WireType.lengthDelimited:
            return try readLengthDelimited(from: data, fieldStartIndex: fieldStartIndex)

        case WireType.startGroup, WireType.endGroup: // groups are deprecated
            throw ProtoError.unsupportedDataType("Groups are deprecated and not supported by this decoder")

        case WireType.bit32:
            if fieldStartIndex + 3 >= data.count {
                throw ProtoError.decodingError("Not enough data left to read 32-bit value")
            }
            let byteValue = data[fieldStartIndex ... (fieldStartIndex + 3)]
            return (byteValue, fieldStartIndex + 4)
        }
    }
}

/// Decoder for Protobuffer data.
/// Coforms to `TopLevelDecoder` from `Combine`, however this is currently ommitted due to compatibility issues.
public class ProtobufferDecoder {
    /// The strategy that this encoder uses to encode `Int`s and `UInt`s.
    public var integerWidthCodingStrategy: IntegerWidthCodingStrategy = .default

    /// Init new decoder instance
    public init() {}

    /// Decodes a Data that was encoded using Protobuffers into
    /// a given struct of type T (T has to conform to Decodable).
    public func decode<T>(_ type: T.Type, from data: Data) throws
    -> T where T: Decodable {
        let decoder = InternalProtoDecoder(from: data, with: integerWidthCodingStrategy)
        return try T(from: decoder)
    }

    /// Can be used to  decode an unknown type, e.g. when no `Decodable` struct is available.
    /// Returns a `UnkeyedDecodingContainer` that can be used to sequentially decode the values the data contains.
    public func decode(from data: Data) throws -> UnkeyedDecodingContainer {
        let decoder = InternalProtoDecoder(from: data, with: integerWidthCodingStrategy)
        return try decoder.unkeyedContainer()
    }
}
