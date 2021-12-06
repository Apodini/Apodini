//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIO
import ApodiniUtils


/// A type which can be encoded into a `repeated` field.
/// - Note: This protocol is intentionally not public, because we don't want users to conform their custom types to it.
protocol ProtobufRepeated {
    /// Type of the repeated elements stored by this type
    static var elementType: Any.Type { get }
    /// Whether the elements are encoded using the packed encoding
    static var isPacked: Bool { get }
    /// Initialises the type by decoding its elements from a ProtobufferDecoder, at the specified fields.
    init<Key: CodingKey>(decodingFrom decoder: _ProtobufferDecoder, forKey key: Key, atFields fields: [ProtobufFieldInfo]) throws
    /// Encodes the object's elements into the encoder, keyed by the specified key.
    func encodeElements<Key: CodingKey>(to encoder: _ProtobufferEncoder, forKey key: Key) throws
}


extension Array: ProtobufRepeated where Element: Codable {
    static var elementType: Any.Type { Element.self }
    
    static var isPacked: Bool {
        switch guessWireType(Element.self)! {
        case .varInt, ._32Bit, ._64Bit:
            return true
        case .lengthDelimited, .startGroup, .endGroup:
            return false
        }
    }
    
    init<Key: CodingKey>( // swiftlint:disable:this cyclomatic_complexity
        decodingFrom decoder: _ProtobufferDecoder,
        forKey key: Key,
        atFields fields: [ProtobufFieldInfo]
    ) throws {
        guard !fields.isEmpty else {
            self = []
            return
        }
        if Self.isPacked {
            guard fields.count == 1 else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Key '\(key.getProtoFieldNumber())' occurs multiple times in the encoded message, which is invalid for packed repeated fields.",
                    underlyingError: nil
                ))
            }
            precondition(fields[0].wireType == .lengthDelimited)
            let (fieldInfo, fieldValueBytesImmut) = try decoder
                ._internalContainer(keyedBy: Key.self)
                .getFieldInfoAndValueBytes(forKey: key, atOffset: nil)
            var fieldValueBytes = fieldValueBytesImmut
            precondition(fieldInfo == fields[0])
            let fieldLength = try fieldValueBytes.readVarInt()
            precondition(fieldValueBytes.readableBytes == Int(fieldLength))
            switch guessWireType(Element.self)! {
            case .varInt: // valueBytes is a bunch of varInts following each other
                let elementTy = Element.self as! ProtoVarIntInitialisable.Type
                var elements: [Element] = []
                while fieldValueBytes.readableBytes > 0 {
                    let varInt = try fieldValueBytes.readVarInt()
                    let element = elementTy.init(varInt: varInt)!
                    elements.append(element as! Element)
                }
                self = elements
                return
            case ._32Bit:
                let u32Size = MemoryLayout<UInt32>.size
                // valueBytes is a bunch of 32-bit values following each other
                precondition(fieldValueBytes.readableBytes.isMultiple(of: u32Size), "Invalid length for packed array of 32-bit values")
                let numElements = fieldValueBytes.readableBytes / u32Size
                let elementTy = Element.self as! Proto32BitValueInitialisable.Type
                self = try (0..<numElements).map { idx in
                    if let u32Val = fieldValueBytes.readInteger(endianness: .little, as: UInt32.self) {
                        if let element = elementTy.init(proto32BitValue: u32Val) {
                            return element as! Element
                        } else {
                            throw DecodingError.dataCorrupted(.init(
                                codingPath: decoder.codingPath.appending(key).appending(FixedCodingKey(intValue: idx)),
                                debugDescription: "Unable to initialize '\(Element.self)' from u32 value \(u32Val)",
                                underlyingError: nil
                            ))
                        }
                    } else {
                        throw DecodingError.dataCorrupted(.init(
                            codingPath: decoder.codingPath.appending(key),
                            debugDescription: "Unable to read element at index \(idx) in packed repeated field.",
                            underlyingError: nil
                        ))
                    }
                }
            case ._64Bit: // valueBytes is a bunch of 64-bit values following each other
                let u64Size = MemoryLayout<UInt64>.size
                precondition(fieldValueBytes.readableBytes.isMultiple(of: u64Size), "Invalid length for packed array of 64-bit values")
                let numElements = fieldValueBytes.readableBytes / u64Size
                let elementTy = Element.self as! Proto64BitValueInitialisable.Type
                self = try (0..<numElements).map { idx in
                    if let u64Val = fieldValueBytes.readInteger(endianness: .little, as: UInt64.self) {
                        if let element = elementTy.init(proto64BitValue: u64Val) {
                            return element as! Element
                        } else {
                            throw DecodingError.dataCorrupted(.init(
                                codingPath: decoder.codingPath.appending(key).appending(FixedCodingKey(intValue: idx)),
                                debugDescription: "Unable to initialize '\(Element.self)' from u64 value \(u64Val)",
                                underlyingError: nil
                            ))
                        }
                    } else {
                        throw DecodingError.dataCorrupted(.init(
                            codingPath: decoder.codingPath.appending(key),
                            debugDescription: "Unable to read element at index \(idx) in packed repeated field.",
                            underlyingError: nil
                        ))
                    }
                }
            case .lengthDelimited, .startGroup, .endGroup:
                throw DecodingError.typeMismatch(Element.self, .init(
                    codingPath: decoder.codingPath.appending(key),
                    debugDescription: "Unsupported wire type for packed repeated field",
                    underlyingError: nil
                ))
            }
        } else {
            let keyedContainer = try decoder._internalContainer(keyedBy: Key.self)
            let fields2 = keyedContainer.fields.getAll(forFieldNumber: key.getProtoFieldNumber())
            precondition(fields == fields2)
            self = try fields.map { fieldInfo -> Element in
                try keyedContainer.decode(Element.self, forKey: key, keyOffset: fieldInfo.keyOffset)
            }
        }
    }
    
    func encodeElements<Key: CodingKey>(to encoder: _ProtobufferEncoder, forKey key: Key) throws {
        guard !isEmpty else {
            return
        }
        if Self.isPacked {
            let dstBufferRef = encoder.dstBufferRef
            let oldWriterIdx = dstBufferRef.value.writerIndex
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
            let elementsBuffer = try { () -> ByteBuffer in
                let elementsBuffer = Box(ByteBuffer())
                let elementsEncoder = _ProtobufferEncoder(codingPath: encoder.codingPath, dstBufferRef: elementsBuffer, context: encoder.context)
                var elementsContainer = elementsEncoder.unkeyedContainer()
                for element in self {
                    try elementsContainer.encode(element)
                }
                return elementsBuffer.value
            }()
            dstBufferRef.value.writeProtoLengthDelimited(elementsBuffer)
        } else {
            encoder.context.markAsRequiredOutput(encoder.codingPath.appending(key))
            defer {
                encoder.context.unmarkAsRequiredOutput(encoder.codingPath.appending(key))
            }
            var keyedContainer = encoder.container(keyedBy: Key.self)
            for element in self {
                try keyedContainer.encode(element, forKey: key)
            }
        }
    }
}
