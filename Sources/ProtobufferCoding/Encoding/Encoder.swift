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
@_implementationOnly import AssociatedTypeRequirementsVisitor


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
    public func encode<T: Encodable>(_ value: T, into buffer: inout ByteBuffer) throws {
        // We (currently) don't care about the actual result of the schema, but we want to ensure that the type structure is valid
        try validateTypeIsProtoCompatible(T.self)
        let dstBufferRef = Box(ByteBuffer())
        let encoder = _ProtobufferEncoder(
            codingPath: [],
            userInfo: [:],
            dstBufferRef: dstBufferRef,
            context: EncoderContext()
        )
        if getProtoCodingKind(type(of: value)) == .message {
            encoder.context.pushSyntax(value is Proto2Codable ? .proto2 : .proto3) // no need to pop here
        }
        try value.encode(to: encoder)
        buffer.writeImmutableBuffer(dstBufferRef.value)
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
            // Note that in this function (the one encoding values into fields, instead of encoding entire messages), our requirements to the
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
            encoder.context.pushSyntax(value is Proto2Codable ? .proto2 : .proto3) // no need to pop here
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
    func markAsRequiredOutput(_ codingPath: [CodingKey]) {
        fieldsMarkedAsRequiredOutput.insert(Self.codingPathToInts(codingPath))
    }
    
    func markAsRequiredOutput(_ codingPaths: [[CodingKey]]) {
        for codingPath in codingPaths {
            markAsRequiredOutput(codingPath)
        }
    }
    
    func unmarkAsRequiredOutput(_ codingPath: [CodingKey]) {
        fieldsMarkedAsRequiredOutput.remove(Self.codingPathToInts(codingPath))
    }
    
    func unmarkAsRequiredOutput(_ codingPaths: [[CodingKey]]) {
        for codingPath in codingPaths {
            unmarkAsRequiredOutput(codingPath)
        }
    }
    
    func isMarkedAsRequiredOutput(_ codingPath: [CodingKey]) -> Bool {
        fieldsMarkedAsRequiredOutput.contains(Self.codingPathToInts(codingPath))
    }
    
    private static func codingPathToInts(_ codingPath: [CodingKey]) -> [Int] {
        codingPath.map { $0.getProtoFieldNumber() }
    }
}


class _ProtobufferEncoder: Encoder { // swiftlint:disable:this type_name
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    let dstBufferRef: Box<ByteBuffer>
    let context: EncoderContext
    
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any] = [:], dstBufferRef: Box<ByteBuffer>, context: EncoderContext) {
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
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        ProtobufferUnkeyedEncodingContainer(codingPath: codingPath, dstBufferRef: dstBufferRef, context: context)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        ProtobufferSingleValueEncodingContainer(codingPath: codingPath, dstBufferRef: dstBufferRef, context: context)
    }
}
