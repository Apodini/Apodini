//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO
import ApodiniUtils
import Foundation


internal struct CodableBox<T> {
    let value: T
}
extension CodableBox: Encodable where T: Encodable {}
extension CodableBox: Decodable where T: Decodable {}


/// The `ProtobufferEncoder` encodes `Encodable` values into protocol buffers
public struct ProtobufferEncoder {
    /// Create a new encoder
    public init() {}
    
    /// Encodes a value
    public func encode<T: Encodable>(_ value: T) throws -> ByteBuffer {
        var buffer = ByteBuffer()
        try encode(value, into: &buffer)
        return buffer
    }
    
    /// Encodes a value into the specified buffer
    public func encode<T: Encodable>(_ value: T, into outBuffer: inout ByteBuffer) throws {
        // We (currently) don't care about the actual result of the schema, but we want to ensure that the type structure is valid
        try validateTypeIsProtoCompatible(T.self)
        let dstBufferRef = Box(ByteBuffer())
        let encoder = _ProtobufferEncoder(
            codingPath: [],
            userInfo: [:],
            dstBufferRef: dstBufferRef,
            context: EncoderContext()
        )
        let isMessage = getProtoCodingKind(type(of: value)) == .message
        if isMessage {
            encoder.context.pushSyntax(value is any Proto2Codable ? .proto2 : .proto3) // no need to pop here
        }
        // NOTE: We have to go through this wrapper type here, in order to give the KeyedEncodingContainer's `encode` function the opportunity
        // to apply type transformations and do some other special handling for specific types.
        // Going through the wrapper type means that the actual value being encoded will go through the KeyedEncodingContainer's encode function,
        // which would not be the case if we called `value.encode(to:)` directly.
        // (The alternative would be to implement everything twice.)
        try CodableBox(value: value).encode(to: encoder)
        let fields = try ProtobufMessageLayoutDecoder.getFields(in: dstBufferRef.value)
        guard fields.count == 1, let field = fields.getAll(forFieldNumber: 1).first else {
            throw ProtoEncodingError.other("Unable to find encoded-to field in encoding buffer")
        }
        let offset: Int
        switch field.valueInfo {
        case .varInt, ._32Bit, ._64Bit:
            offset = field.valueOffset
        case .lengthDelimited(dataLength: _, let dataOffset):
            offset = field.valueOffset + (isMessage ? dataOffset : 0)
        }
        dstBufferRef.value.moveReaderIndex(forwardBy: offset)
        outBuffer.writeImmutableBuffer(dstBufferRef.value)
    }
    
    /// Encodes a value, at the specified field
    public func encode<T: Encodable>(_ value: T, asField field: ProtoType.MessageField) throws -> ByteBuffer {
        var buffer = ByteBuffer()
        try encode(value, into: &buffer, asField: field)
        return buffer
    }
    
    /// Encodes a value into the specified buffer, at the specified field
    public func encode<T: Encodable>(
        _ value: T,
        into buffer: inout ByteBuffer,
        asField field: ProtoType.MessageField
    ) throws {
        do {
            // We (currently) don't care about the actual result of the schema, but we want to ensure that the type structure is valid
            try validateTypeIsProtoCompatible(T.self)
        } catch let error as ProtoValidationError {
            // Note that in this function (the one encoding values into fields, instead of encoding entire messages),
            // our requirements to `T` are a bit more relaxed than in the "encode full value" functions...
            switch error {
            case .topLevelArrayNotAllowed:
                // We swallow all "T cannot be a top-level type" errors, since we're not encoding T into a top-level type (but rather into a field).
                break
            default:
                throw error
            }
        }
        let dstBufferRef = Box(ByteBuffer())
        let encoder = _ProtobufferEncoder(codingPath: [], dstBufferRef: dstBufferRef, context: EncoderContext())
        if getProtoCodingKind(type(of: value)) == .message {
            encoder.context.pushSyntax(value is any Proto2Codable ? .proto2 : .proto3) // no need to pop here
        }
        var keyedEncoder = encoder.container(keyedBy: FixedCodingKey.self)
        try keyedEncoder.encode(value, forKey: .init(intValue: field.fieldNumber))
        buffer.writeImmutableBuffer(dstBufferRef.value)
    }
}


class EncoderContext {
    private var syntaxStack = Stack<ProtoSyntax>()
    private var fieldsMarkedAsRequiredOutput: Set<[Int]> = [] // int values of the coding path to the field
    
    /// The current syntax.
    /// - Note: Since proto2 and proto3 messages can be contained in each other, the value of this property can change while encoding an object.
    var syntax: ProtoSyntax { syntaxStack.peek()! }
    
    init(syntax: ProtoSyntax = .proto3) {
        syntaxStack.push(syntax)
    }
    
    func pushSyntax(_ syntax: ProtoSyntax) {
        syntaxStack.push(syntax)
    }
    
    func popSyntax() {
        precondition(syntaxStack.count >= 2, "Imbalanced pop")
        syntaxStack.pop()
    }
    
    /// Marking a coding path as "required output" will indicate to the encoder that values for this field should
    /// always be written into the proto buffer, even if the value is the field's zero default value.
    func markAsRequiredOutput(_ codingPath: [any CodingKey]) {
        fieldsMarkedAsRequiredOutput.insert(Self.codingPathToFieldNumbers(codingPath))
    }
    
    func markAsRequiredOutput(_ codingPaths: [[any CodingKey]]) {
        for codingPath in codingPaths {
            markAsRequiredOutput(codingPath)
        }
    }
    
    func unmarkAsRequiredOutput(_ codingPath: [any CodingKey]) {
        fieldsMarkedAsRequiredOutput.remove(Self.codingPathToFieldNumbers(codingPath))
    }
    
    func unmarkAsRequiredOutput(_ codingPaths: [[any CodingKey]]) {
        for codingPath in codingPaths {
            unmarkAsRequiredOutput(codingPath)
        }
    }
    
    func isMarkedAsRequiredOutput(_ codingPath: [any CodingKey]) -> Bool {
        fieldsMarkedAsRequiredOutput.contains(Self.codingPathToFieldNumbers(codingPath))
    }
    
    private static func codingPathToFieldNumbers(_ codingPath: [any CodingKey]) -> [Int] {
        codingPath.map { $0.getProtoFieldNumber() }
    }
}


class _ProtobufferEncoder: Encoder { // swiftlint:disable:this type_name
    let codingPath: [any CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    let dstBufferRef: Box<ByteBuffer>
    let context: EncoderContext
    
    init(codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any] = [:], dstBufferRef: Box<ByteBuffer>, context: EncoderContext) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.dstBufferRef = dstBufferRef
        self.context = context
    }
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(internalKeyedContainer(keyedBy: Key.self))
    }
    
    /// Allows access to the actual internal `ProtobufferKeyedEncodingContainer` type, not the type-erased wrapper used by the standard library.
    /// This is useful for clients that need to access protobuf-specific functionality.
    func internalKeyedContainer<Key: CodingKey>(keyedBy _: Key.Type) -> ProtobufferKeyedEncodingContainer<Key> {
        ProtobufferKeyedEncodingContainer(codingPath: codingPath, dstBufferRef: dstBufferRef, context: context)
    }
    
    func unkeyedContainer() -> any UnkeyedEncodingContainer {
        internalUnkeyedContainer()
    }
    
    func internalUnkeyedContainer() -> ProtobufferUnkeyedEncodingContainer {
        ProtobufferUnkeyedEncodingContainer(codingPath: codingPath, dstBufferRef: dstBufferRef, context: context)
    }
    
    func singleValueContainer() -> any SingleValueEncodingContainer {
        ProtobufferSingleValueEncodingContainer(codingPath: codingPath, dstBufferRef: dstBufferRef, context: context)
    }
}
