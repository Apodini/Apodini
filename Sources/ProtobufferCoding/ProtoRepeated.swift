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


/// A type which can be both encoded and decoded as a `repeated` proto field.
typealias ProtobufRepeatedCodable = ProtobufRepeatedEncodable & ProtobufRepeatedDecodable


/// A type which can be encoded into a `repeated` field.
/// - Note: This protocol is intentionally not public, because we don't want users to conform their custom types to it.
protocol ProtobufRepeatedEncodable {
    static var elementType: any Encodable.Type { get }
    /// Whether the elements are encoded using the packed encoding
    static var isPacked: Bool { get }
    /// Encodes the object's elements into the encoder, keyed by the specified key.
    func encodeElements<Key: CodingKey>(to encoder: _ProtobufferEncoder, forKey key: Key) throws
    /// The elements in the repeated value.
    /// - Note: This is used by `encodeElements(to:forKey:)`'s default implementation to get the elements in the repeated value.
    ///         This computed property should return an array of objects of the same type as `Self.elementType`.
    var typeErasedElements: [any Encodable] { get }
}


/// A type which can be decoded from a `repeated` field.
/// - Note: This protocol is intentionally not public, because we don't want users to conform their custom types to it.
protocol ProtobufRepeatedDecodable {
    static var elementType: any Decodable.Type { get }
    /// Whether the elements are encoded using the packed encoding
    static var isPacked: Bool { get }
    /// Initialises the type by decoding its elements from a ProtobufferDecoder, at the specified fields.
    init<Key: CodingKey>(decodingFrom decoder: _ProtobufferDecoder, forKey key: Key, atFields fields: [ProtobufFieldInfo]) throws
    /// Initializes the repeated type with the specified elements.
    /// - Note: This initializer is called by `ProtobufRepeated`'s default `decodingFrom:` initializer. It is guaranteed that the elements have the same type as `Self.elementType`.
    init(typeErasedElements elements: [Any])
}


extension ProtobufRepeatedEncodable {
    func encodeElements<Key: CodingKey>(to encoder: _ProtobufferEncoder, forKey key: Key) throws {
        let elements = self.typeErasedElements
        guard !elements.isEmpty else {
            return
        }
        if Self.isPacked {
            let dstBufferRef = encoder.dstBufferRef
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
            let elementsBuffer = try { () -> ByteBuffer in
                let elementsBuffer = Box(ByteBuffer())
                let elementsEncoder = _ProtobufferEncoder(codingPath: encoder.codingPath, dstBufferRef: elementsBuffer, context: encoder.context)
                var elementsContainer = elementsEncoder.internalUnkeyedContainer()
                for element in elements {
                    try elementsContainer._encode(element)
                }
                return elementsBuffer.value
            }()
            dstBufferRef.value.writeProtoLengthDelimited(elementsBuffer)
        } else {
            encoder.context.markAsRequiredOutput(encoder.codingPath.appending(key))
            defer {
                encoder.context.unmarkAsRequiredOutput(encoder.codingPath.appending(key))
            }
            var keyedContainer = encoder.internalKeyedContainer(keyedBy: Key.self)
            for element in elements {
                try keyedContainer._encode(element, forKey: key)
            }
        }
    }
}


extension ProtobufRepeatedDecodable {
    init<Key: CodingKey>( // swiftlint:disable:this cyclomatic_complexity
        decodingFrom decoder: _ProtobufferDecoder,
        forKey key: Key,
        atFields fields: [ProtobufFieldInfo]
    ) throws {
        guard !fields.isEmpty else {
            self.init(typeErasedElements: [])
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
            switch guessWireType(Self.elementType)! {
            case .varInt: // valueBytes is a bunch of varInts following each other
                let elementTy = Self.elementType as! any ProtoVarIntInitialisable.Type
                var elements: [Any] = []
                while fieldValueBytes.readableBytes > 0 {
                    let varInt = try fieldValueBytes.readVarInt()
                    let element = elementTy.init(varInt: varInt)!
                    elements.append(element)
                }
                self.init(typeErasedElements: elements)
                return
            case ._32Bit:
                let u32Size = MemoryLayout<UInt32>.size
                // valueBytes is a bunch of 32-bit values following each other
                precondition(fieldValueBytes.readableBytes.isMultiple(of: u32Size), "Invalid length for packed array of 32-bit values")
                let numElements = fieldValueBytes.readableBytes / u32Size
                let elementTy = Self.elementType as! any Proto32BitValueInitialisable.Type
                self.init(typeErasedElements: try (0..<numElements).map { idx in
                    if let u32Val = fieldValueBytes.readInteger(endianness: .little, as: UInt32.self) {
                        if let element = elementTy.init(proto32BitValue: u32Val) {
                            return element
                        } else {
                            throw DecodingError.dataCorrupted(.init(
                                codingPath: decoder.codingPath.appending(key).appending(FixedCodingKey(intValue: idx)),
                                debugDescription: "Unable to initialize '\(Self.elementType)' from u32 value \(u32Val)",
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
                })
            case ._64Bit: // valueBytes is a bunch of 64-bit values following each other
                let u64Size = MemoryLayout<UInt64>.size
                precondition(fieldValueBytes.readableBytes.isMultiple(of: u64Size), "Invalid length for packed array of 64-bit values")
                let numElements = fieldValueBytes.readableBytes / u64Size
                let elementTy = Self.elementType as! any Proto64BitValueInitialisable.Type
                self.init(typeErasedElements: try (0..<numElements).map { idx in
                    if let u64Val = fieldValueBytes.readInteger(endianness: .little, as: UInt64.self) {
                        if let element = elementTy.init(proto64BitValue: u64Val) {
                            return element
                        } else {
                            throw DecodingError.dataCorrupted(.init(
                                codingPath: decoder.codingPath.appending(key).appending(FixedCodingKey(intValue: idx)),
                                debugDescription: "Unable to initialize '\(Self.elementType)' from u64 value \(u64Val)",
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
                })
            case .lengthDelimited, .startGroup, .endGroup:
                throw DecodingError.typeMismatch(Self.elementType, .init(
                    codingPath: decoder.codingPath.appending(key),
                    debugDescription: "Unsupported wire type for packed repeated field",
                    underlyingError: nil
                ))
            }
        } else {
            let keyedContainer = try decoder._internalContainer(keyedBy: Key.self)
            let fields2 = keyedContainer.fields.getAll(forFieldNumber: key.getProtoFieldNumber())
            precondition(fields == fields2)
            self.init(typeErasedElements: try fields.map { fieldInfo -> Any in
                try keyedContainer._decode(Self.elementType, forKey: key, keyOffset: fieldInfo.keyOffset)
            })
        }
    }
}


// MARK: Array

extension Array: ProtobufRepeatedEncodable where Element: Encodable {
    static var elementType: any Encodable.Type { Element.self }
    
    static var isPacked: Bool {
        switch guessWireType(Element.self)! {
        case .varInt, ._32Bit, ._64Bit:
            return true
        case .lengthDelimited, .startGroup, .endGroup:
            return false
        }
    }
    
    var typeErasedElements: [any Encodable] {
        self
    }
}


extension Array: ProtobufRepeatedDecodable where Element: Decodable {
    static var elementType: any Decodable.Type { Element.self }
    
    static var isPacked: Bool {
        switch guessWireType(Element.self)! {
        case .varInt, ._32Bit, ._64Bit:
            return true
        case .lengthDelimited, .startGroup, .endGroup:
            return false
        }
    }
    
    init(typeErasedElements elements: [Any]) {
        self = elements as! [Element]
    }
}


// MARK: Dictionary

/// A type which can be encoded and decoded as a `map<K, V>` field in proto3, with `K` and `V` also being proto-compatible types.
/// In Swift, proto3 `map<K, V>`s are represented as `Dictionary<K, V>` objects.
typealias ProtobufMapCodable = ProtobufMapEncodable & ProtobufMapDecodable


/// A proto3 `map<K, V>`-encodable type, i.e. a `Dictionary<K, V>` in Swift. Maps are encoded as repeated fields, so we inherit the `ProtobufRepeatedEncodable` protocol to get that behaviour.
protocol ProtobufMapEncodable: ProtobufRepeatedEncodable {
    static var keyType: any Encodable.Type { get }
    static var valueType: any Encodable.Type { get }
}


/// A proto3 `map<K, V>`-decodable type, i.e. a `Dictionary<K, V>` in Swift. Maps are encoded as repeated fields, so we inherit the `ProtobufRepeatedEncodable` protocol to get that behaviour.
protocol ProtobufMapDecodable: ProtobufRepeatedDecodable {
    static var keyType: any Decodable.Type { get }
    static var valueType: any Decodable.Type { get }
}


/// Internal helper protocol to identify `ProtobufMapFieldEntry` objects.
/// - Note: The `ProtobufMapFieldEntry` type should be the only type conforming to this protocol!
protocol AnyProtobufMapFieldEntry {}


/// Internal proto message type which is used to model the key-value-pair entries in a proto3 map.
struct ProtobufMapFieldEntry<Key, Value>: ProtoTypeInPackage, AnyProtobufMapFieldEntry {
    static var package: ProtobufPackageUnit { .inlineInParentTypePackage }
    
    let key: Key
    let value: Value
}

extension ProtobufMapFieldEntry: Encodable where Key: Encodable, Value: Encodable {}
extension ProtobufMapFieldEntry: Decodable where Key: Decodable, Value: Decodable {}

extension ProtobufMapFieldEntry: Equatable where Key: Equatable, Value: Equatable {}
extension ProtobufMapFieldEntry: Hashable where Key: Hashable, Value: Hashable {}


extension Dictionary: ProtobufMapEncodable & ProtobufRepeatedEncodable where Key: Encodable, Value: Encodable {
    static var keyType: any Encodable.Type { Key.self }
    static var valueType: any Encodable.Type { Value.self }
    
    static var elementType: any Encodable.Type { ProtobufMapFieldEntry<Key, Value>.self }
    static var isPacked: Bool { false }
    
    var typeErasedElements: [any Encodable] {
        self.map { ProtobufMapFieldEntry(key: $0, value: $1) }
    }
}


extension Dictionary: ProtobufMapDecodable & ProtobufRepeatedDecodable where Key: Decodable, Value: Decodable {
    static var keyType: any Decodable.Type { Key.self }
    static var valueType: any Decodable.Type { Value.self }
    
    static var elementType: any Decodable.Type { ProtobufMapFieldEntry<Key, Value>.self }
    static var isPacked: Bool { false }
    
    init(typeErasedElements elements: [Any]) {
        let elements = elements as! [ProtobufMapFieldEntry<Key, Value>]
        self.init(uniqueKeysWithValues: elements.map { ($0.key, $0.value) })
    }
}
