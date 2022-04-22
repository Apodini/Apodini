//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable syntactic_sugar

import NIO
import Apodini
import ApodiniUtils
import Foundation
@_implementationOnly import Runtime
@_implementationOnly import AssociatedTypeRequirementsVisitor


let protobufferUnsupportedNumericTypes = Set(
    Int8.self, UInt8.self, Int16.self, UInt16.self
)


func throwUnsupportedNumericTypeEncodingError(value: Any, codingPath: [CodingKey]) throws -> Never {
    precondition(
        protobufferUnsupportedNumericTypes.contains(type(of: value)),
        "Asked to throw an \"unsupported numeric type\" error for a type that is not, in fact, an unsupported numeric type."
    )
    throw EncodingError.invalidValue(value, .init(
        codingPath: codingPath,
        debugDescription: "Type '\(type(of: value))' is not a supported type for proto fields.",
        underlyingError: nil
    ))
}


func throwUnsupportedNumericTypeDecodingError(_ attemptedType: Any.Type, codingPath: [CodingKey]) throws -> Never {
    precondition(
        protobufferUnsupportedNumericTypes.contains(attemptedType),
        "Asked to throw an \"unsupported numeric type\" error for a type that it not, in fact, an unsupported numeric type."
    )
    precondition(protobufferUnsupportedNumericTypes.contains(attemptedType))
    throw DecodingError.typeMismatch(attemptedType, .init(
        codingPath: codingPath,
        debugDescription: "Type '\(attemptedType)' is not a supported type for proto fields.",
        underlyingError: nil
    ))
}


struct ProtobufferKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let codingPath: [CodingKey]
    let dstBufferRef: Box<ByteBuffer>
    let context: EncoderContext
    
    init(codingPath: [CodingKey], dstBufferRef: Box<ByteBuffer>, context: EncoderContext) {
        self.codingPath = codingPath
        self.dstBufferRef = dstBufferRef
        self.context = context
    }
    
    mutating func encodeNil(forKey key: Key) throws {
        fatalError("Not implemented (key: \(key))")
    }
    
    private func shouldEncodeNonnilValue(forKey key: Key, isDefaultZeroValue: Bool) -> Bool {
        switch context.syntax {
        case .proto2:
            // proto2 always encodes non-nil values, regardless of whether or not they're optional,
            // and regardless of whether or not they're the field type's "default zero" value
            return true
        case .proto3:
            let isRequiredOutput = context.isMarkedAsRequiredOutput(codingPath.appending(key))
            return isRequiredOutput ? true : !isDefaultZeroValue
        }
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        if shouldEncodeNonnilValue(forKey: key, isDefaultZeroValue: value == false) {
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .varInt)
            dstBufferRef.value.writeProtoVarInt(UInt8(value ? 1 : 0))
        }
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        guard shouldEncodeNonnilValue(forKey: key, isDefaultZeroValue: value.isEmpty) else {
            // Empty strings are simply omitted from the buffer
            return
        }
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
        dstBufferRef.value.writeProtoLengthDelimited(value.utf8)
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        guard shouldEncodeNonnilValue(forKey: key, isDefaultZeroValue: value.isZero) else {
            // Zero values are simply omitted
            return
        }
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: ._32Bit)
        dstBufferRef.value.writeProtoFloat(value)
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        guard shouldEncodeNonnilValue(forKey: key, isDefaultZeroValue: value.isZero) else {
            // Zero values are simply omitted
            return
        }
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: ._64Bit)
        dstBufferRef.value.writeProtoDouble(value)
    }
    
    mutating func encodeVarInt<T: FixedWidthInteger>(_ value: T, forKey key: Key, alwaysEncodeZeroValues: Bool = false) throws {
        guard alwaysEncodeZeroValues || shouldEncodeNonnilValue(forKey: key, isDefaultZeroValue: value == T.zero) else {
            return
        }
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .varInt)
        dstBufferRef.value.writeProtoVarInt(value)
    }
    
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        try encodeVarInt(value, forKey: key)
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath.appending(key))
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath.appending(key))
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        try encodeVarInt(value, forKey: key)
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        try encodeVarInt(value, forKey: key)
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        try encodeVarInt(value, forKey: key)
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath.appending(key))
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath.appending(key))
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        try encodeVarInt(value, forKey: key)
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        try encodeVarInt(value, forKey: key)
    }
    
    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        try _encode(value, forKey: key)
    }
    
    
    mutating func _encode(_ value: Encodable, forKey key: Key) throws { // swiftlint:disable:this cyclomatic_complexity identifier_name
        func encodeLengthDelimitedKeyedBytes<S: Collection>(_ sequence: S) where S.Element == UInt8 {
            precondition(!sequence.isEmpty)
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
            dstBufferRef.value.writeProtoLengthDelimited(sequence)
        }
        
        if getProtoCodingKind(type(of: value)) == .message {
            context.pushSyntax(value is Proto2Codable ? .proto2 : .proto3)
            precondition((value is Proto2Codable) == (getProtoSyntax(type(of: value)) == .proto2))
        }
        defer {
            if getProtoCodingKind(type(of: value)) == .message {
                context.popSyntax()
            }
        }
        
        if let optionalVal = value as? AnyOptional {
            try _encodeIfPresent(optionalVal.typeErasedWrappedValue as! Encodable?, forKey: key)
        } else if value is _ProtobufEmbeddedType {
            // We're encoding an embedded type (i.e. a oneof), which means that we completely ignore the key
            // and simply encode the set value as if it were a normal field
            precondition(value is AnyProtobufEnumWithAssociatedValues)
            let possibleKeys: [CodingKey] = (type(of: value) as! AnyProtobufEnumWithAssociatedValues.Type).getCodingKeysType().allCases
            let possibleCodingPaths = possibleKeys.map { self.codingPath.appending($0) }
            context.markAsRequiredOutput(possibleCodingPaths)
            defer {
                context.unmarkAsRequiredOutput(possibleCodingPaths)
            }
            let encoder = _ProtobufferEncoder(codingPath: self.codingPath, dstBufferRef: dstBufferRef, context: context)
            try value.encode(to: encoder)
        } else if let enumVal = value as? AnyProtobufEnum {
            let enumTy = type(of: enumVal)
            switch getProtoSyntax(enumTy) {
            case .proto2:
                if enumVal.rawValue == enumTy.allCases.first!.rawValue && !context.isMarkedAsRequiredOutput(codingPath.appending(key)) {
                    // We'd encode the default value, which can be omitted
                    return
                }
            case .proto3:
                if enumVal.rawValue == 0 && !context.isMarkedAsRequiredOutput(codingPath.appending(key)) {
                    // We'd encode the default value, which can be omitted
                    return
                }
            }
            try encodeVarInt(enumVal.rawValue, forKey: key, alwaysEncodeZeroValues: true)
        } else if let string = value as? String {
            try encode(string, forKey: key)
        } else if let bool = value as? Bool {
            try encode(bool, forKey: key)
        } else if protobufferUnsupportedNumericTypes.contains(type(of: value)) {
            try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath.appending(key))
        } else if let intValue = value as? Int {
            precondition(type(of: value) == Int.self)
            try encode(intValue, forKey: key)
        } else if let intValue = value as? UInt {
            precondition(type(of: value) == UInt.self)
            try encode(intValue, forKey: key)
        } else if let intValue = value as? Int32 {
            precondition(type(of: value) == Int32.self)
            try encode(intValue, forKey: key)
        } else if let intValue = value as? UInt32 {
            precondition(type(of: value) == UInt32.self)
            try encode(intValue, forKey: key)
        } else if let intValue = value as? Int64 {
            precondition(type(of: value) == Int64.self)
            try encode(intValue, forKey: key)
        } else if let intValue = value as? UInt64 {
            precondition(type(of: value) == UInt64.self)
            try encode(intValue, forKey: key)
        } else if let doubleValue = value as? Double {
            precondition(type(of: value) == Double.self)
            try encode(doubleValue, forKey: key)
        } else if let floatValue = value as? Float {
            precondition(type(of: value) == Float.self)
            try encode(floatValue, forKey: key)
        } else if let uuidValue = value as? Foundation.UUID {
            precondition(type(of: value) == UUID.self)
            try encode(uuidValue.uuidString, forKey: key)
        } else if let dateValue = value as? Foundation.Date {
            precondition(type(of: value) == Date.self)
            let timestamp = ProtoTimestamp(timeIntervalSince1970: dateValue.timeIntervalSince1970)
            try encode(timestamp, forKey: key)
        } else if let urlValue = value as? Foundation.URL {
            precondition(type(of: value) == URL.self)
            try encode(urlValue.absoluteURL.resolvingSymlinksInPath().absoluteString, forKey: key)
        } else if let blob = value as? Apodini.Blob {
            try encode(ApodiniBlob(blob: blob), forKey: key)
        } else if let array = value as? Array<UInt8>, type(of: value) == Array<UInt8>.self {
            // ^^^ We need the additional type(of:) check bc Swift will happily convert
            // empty arrays of type X to empty arrays of type Y :/
            precondition(type(of: value) == Array<UInt8>.self)
            // Protobuffer doesn't have a one-byte type, so this wouldn't be valid anyway, meaning that we can safely interpret an `[UInt8]` as "data"
            encodeLengthDelimitedKeyedBytes(array)
        } else if let data = value as? Data {
            encodeLengthDelimitedKeyedBytes(data)
        } else if let protobufRepeatedTy = value as? ProtobufRepeatedEncodable {
            let encoder = _ProtobufferEncoder(codingPath: codingPath, dstBufferRef: dstBufferRef, context: context)
            try protobufRepeatedTy.encodeElements(to: encoder, forKey: key)
        } else {
            // We're encoding something that's not a message. In this case we do not apply explicit length-decoding.
            // Note that this is somehwat imperfect. Ideally we'd get rid of the message check above and somehow determine that dynamically!
            // (i.e. determine whether T is a struct like Int (where we don't need to apply additional length-encoding),
            // a struct like String (where the length-encoding would already have happened), or a struct like MyCustomStructWhatever (where
            // we'd need to apply length-encoding)
            switch getProtoCodingKind(type(of: value)) {
            case nil:
                fatalError("Unable to encode value of type: '\(type(of: value))': unable to get proto coding kind")
            case .message:
                let bufferRef = Box(ByteBuffer())
                let encoder = _ProtobufferEncoder(codingPath: self.codingPath.appending(key), dstBufferRef: bufferRef, context: context)
                try value.encode(to: encoder)
                self.dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: guessWireType(type(of: value))!)
                precondition(self.dstBufferRef.value.writeProtoLengthDelimited(bufferRef.value) > 0)
            case .primitive, .enum, .repeated, .oneof:
                fatalError("Unreachable, already handled above")
            }
        }
    }
    
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        KeyedEncodingContainer(ProtobufferKeyedEncodingContainer<NestedKey>(
            codingPath: codingPath.appending(key),
            dstBufferRef: dstBufferRef,
            context: context
        ))
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError("Not implemented.")
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError("Not implemented.")
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        fatalError("Not implemented.")
    }
    
    
    // MARK: Optionals
    
    mutating func encodeIfPresent(_ value: Bool?, forKey key: Key) throws { // swiftlint:disable:this discouraged_optional_boolean
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: String?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func encodeIfPresent<T: Encodable>(_ value: T?, forKey key: Key) throws {
        try _encodeIfPresent(value, forKey: key)
    }
    
    mutating func _encodeIfPresent(_ value: Encodable?, forKey key: Key) throws { // swiftlint:disable:this identifier_name
        // We're encoding an Optional. this is a bit tricky bc we have to properly handle proto2 and proto3's optional encoding behaviour here.
        // We're using proto3 everywhere, with the exception of the descriptors proto definitions.
        // (These are still defined as proto2 message types, so we have to match that behaviour.)
        // In order to differentiate between fields that were explicitly set to nil, and fields that were set to the type's default "zero value",
        // which wouldn't be possible were we to simply skip encoding the field into the buffer in both cases, we always encode non-nil optionals
        // into the buffer, regardless of whether or not the value is the zero value (which we'd normally skip).
        if let value = value {
            // the optional field has a value, so we have to always encode the field
            context.markAsRequiredOutput(codingPath.appending(key))
            defer {
                context.unmarkAsRequiredOutput(codingPath.appending(key))
            }
            try _encode(value, forKey: key)
        } else {
            // The optional field does not have a value, so we don't encode anything into the buffer
        }
    }
}


// MARK: Utilities

protocol AnyEncodableATRVisitorBase: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = AnyEncodableATRVisitorBase
    associatedtype Input = Encodable
    associatedtype Output

    func callAsFunction<T: Encodable>(_ value: T) -> Output
}

extension AnyEncodableATRVisitorBase {
    @inline(never)
    @_optimize(none)
    func _test() { // swiftlint:disable:this identifier_name
        _ = self(12)
    }
}


protocol AnyKeyedEncodingContainerContainerProtocol {
    func encode<T: Encodable>(_ value: T) throws
}


class ProtoKeyedEncodingContainerContainer<Key: CodingKey>: AnyKeyedEncodingContainerContainerProtocol {
    let key: Key
    var keyedEncodingContainer: KeyedEncodingContainer<Key>
    
    init(key: Key, keyedEncodingContainer: KeyedEncodingContainer<Key>) {
        self.key = key
        self.keyedEncodingContainer = keyedEncodingContainer
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        try keyedEncodingContainer.encode(value, forKey: key)
    }
}


struct AnyEncodableEncodeIntoKeyedEncodingContainerATRVisitor: AnyEncodableATRVisitorBase { // swiftlint:disable:this type_name
    let containerContainer: AnyKeyedEncodingContainerContainerProtocol
    
    func callAsFunction<T: Encodable>(_ value: T) -> Result<Void, Error> {
        .init(catching: { try containerContainer.encode(value) })
    }
}
