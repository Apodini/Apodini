//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO
import Foundation
import ApodiniUtils


/// The `ProtobufferDecoder` decodes `Decodable` types from protocol buffers
public struct ProtobufferDecoder {
    /// Creates a new decoder
    public init() {}
    
    /// Decodes a value from the specified `Data` object
    public func decode<T: Decodable>(_: T.Type, from data: Data) throws -> T {
        try decode(T.self, from: ByteBuffer(data: data))
    }
    
    /// Decodes a value from te specified buffer
    public func decode<T: Decodable>(_: T.Type, from buffer: ByteBuffer) throws -> T {
        // We (currently) don't care about the actual result of the schema, but we want to ensure that the type structure is valid
        try validateTypeIsProtoCompatible(T.self)
        // Similar to how the Encoder works, we have to wrap the bytes in a message, to ensure that the decoding goes through the KeyedDecodingContainer,
        // which will apply type transformations and other special handling.
        // Technically this is only necessary for siruations where a type with special handling (e.g.: Date, URL, UUID, etc) is used as a top-level type
        // (which is rather rare), but since there is no good way of checking this we just have all types go through this.
        var wrappingBuffer = ByteBufferAllocator().buffer(capacity: buffer.readableBytes + 4)
        guard let wireType = guessWireType(T.self) else {
            let decoder = _ProtobufferDecoder(codingPath: [], buffer: buffer)
            return try T(from: decoder)
        }
        wrappingBuffer.writeInteger((1 << 3) | wireType.rawValue, as: UInt8.self)
        switch wireType {
        case ._32Bit, ._64Bit, .varInt:
            break
        case .lengthDelimited:
            wrappingBuffer.writeProtoVarInt(buffer.readableBytes)
        case .startGroup, .endGroup:
            break
        }
        wrappingBuffer.writeImmutableBuffer(buffer)
        let decoder = _ProtobufferDecoder(codingPath: [], buffer: wrappingBuffer)
        return try CodableBox<T>(from: decoder).value
    }
    
    /// Decodes a value from the specified buffer, at the specified field
    public func decode<T: Decodable>(
        _: T.Type,
        from buffer: ByteBuffer,
        atField fieldInfo: ProtoType.MessageField
    ) throws -> T {
        do {
            // We (currently) don't care about the actual result of the schema, but we want to ensure that the type structure is valid
            try validateTypeIsProtoCompatible(T.self)
        } catch let error as ProtoValidationError {
            // Note that in this function (the one decoding values from fields, instead of encoding entire messages),
            // our requirements to `T` are a bit more relaxed than in the "decode full value" functions...
            switch error {
            case .topLevelArrayNotAllowed:
                // We swallow all "T cannot be a top-level type" errors, since we're not decoding T as a top-level type (but rather from a field).
                break
            default:
                throw error
            }
        }
        let decoder = _ProtobufferDecoder(codingPath: [], buffer: buffer)
        let keyedDecoder = try decoder.container(keyedBy: FixedCodingKey.self)
        return try keyedDecoder.decode(T.self, forKey: .init(intValue: fieldInfo.fieldNumber, stringValue: fieldInfo.name))
    }
}


class _ProtobufferDecoder: Decoder { // swiftlint:disable:this type_name
    let codingPath: [any CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    let buffer: ByteBuffer
    
    init(codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any] = [:], buffer: ByteBuffer) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.buffer = buffer
    }
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        try KeyedDecodingContainer(ProtobufferDecoderKeyedDecodingContainer<Key>(
            codingPath: self.codingPath,
            buffer: buffer
        ))
    }
    
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        ProtobufferUnkeyedDecodingContainer(codingPath: codingPath, buffer: buffer)
    }
    
    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        // NOTE: We really don't want to end up here, except for cases where the caller knows what it's doing.
        ProtobufferSingleValueDecodingContainer(codingPath: codingPath, buffer: buffer)
    }
    
    func _internalContainer<Key: CodingKey>(keyedBy _: Key.Type) throws -> ProtobufferDecoderKeyedDecodingContainer<Key> { // swiftlint:disable:this identifier_name line_length
        try ProtobufferDecoderKeyedDecodingContainer<Key>(codingPath: codingPath, buffer: buffer)
    }
}
