import NIO
import ApodiniUtils
import Foundation
@_implementationOnly import Runtime
@_implementationOnly import AssociatedTypeRequirementsVisitor


extension Set where Element == ObjectIdentifier {
    init(_ types: Any.Type...) {
        self.init(types)
    }
    
    init<S>(_ other: S) where S: Sequence, S.Element == Any.Type {
        self = Set(other.map { ObjectIdentifier($0) })
    }
    
    func contains(_ other: Any.Type) -> Bool {
        contains(ObjectIdentifier(other))
    }
}


let protobufferUnsupportedNumericTypes = Set(
    Int8.self, UInt8.self, Int16.self, UInt16.self
)


struct ProtobufferKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let codingPath: [CodingKey]
    let dstBufferRef: Box<ByteBuffer>
    let context: _EncoderContext
    
    init(codingPath: [CodingKey], dstBufferRef: Box<ByteBuffer>, context: _EncoderContext) {
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
            return true // proto2 always encodes non-nil values, regardless of whether or not they're optional, and regardless of whether or not they're the field type's "default zero" value
        case .proto3:
            let isRequiredOutput = context.isMarkedAsRequiredOutput(codingPath.appending(key))
            return isRequiredOutput ? true : !isDefaultZeroValue
        }
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        if shouldEncodeNonnilValue(forKey: key, isDefaultZeroValue: value == false) {
        //if value || context.isMarkedAsOptional(codingPath.appending(key)) {
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .varInt)
            dstBufferRef.value.writeProtoVarInt(UInt8(value ? 1 : 0))
        }
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        //guard !value.isEmpty || context.isMarkedAsOptional(codingPath.appending(key)) else {
        guard shouldEncodeNonnilValue(forKey: key, isDefaultZeroValue: value.isEmpty) else {
            // Empty strings are simply omitted from the buffer
            return
        }
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
        dstBufferRef.value.writeProtoLengthDelimited(value.utf8)
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        //guard !value.isZero || context.isMarkedAsOptional(codingPath.appending(key)) else {
        guard shouldEncodeNonnilValue(forKey: key, isDefaultZeroValue: value.isZero) else {
            // Zero values are simply omitted
            return
        }
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: ._32Bit)
        dstBufferRef.value.writeProtoFloat(value)
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        //guard !value.isZero || context.isMarkedAsOptional(codingPath.appending(key)) else {
        guard shouldEncodeNonnilValue(forKey: key, isDefaultZeroValue: value.isZero) else {
            // Zero values are simply omitted
            return
        }
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: ._64Bit)
        dstBufferRef.value.writeProtoDouble(value)
    }
    
    mutating func _encodeVarInt<T: FixedWidthInteger>(_ value: T, forKey key: Key) throws {
        //guard value != T.zero || context.isMarkedAsOptional(codingPath.appending(key)) else {
        guard shouldEncodeNonnilValue(forKey: key, isDefaultZeroValue: value == T.zero) else {
            return
        }
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .varInt)
        dstBufferRef.value.writeProtoVarInt(value)
    }
    
    private func throwUnsupportedNumericTypeError(value: Any, forKey key: Key) throws {
        precondition(protobufferUnsupportedNumericTypes.contains(type(of: value)), "Asked to throw an \"unsupported numeric type\" error for a type that it not, in fact, an unsupported numeric type.")
        throw EncodingError.invalidValue(value, .init(
            codingPath: codingPath.appending(key),
            debugDescription: "Type '\(type(of: value))' is not available in protobuf.",
            underlyingError: nil
        ))
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        try _encodeVarInt(value, forKey: key)
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        try throwUnsupportedNumericTypeError(value: value, forKey: key)
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        try throwUnsupportedNumericTypeError(value: value, forKey: key)
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        try _encodeVarInt(value, forKey: key)
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        try _encodeVarInt(value, forKey: key)
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        try _encodeVarInt(value, forKey: key)
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        try throwUnsupportedNumericTypeError(value: value, forKey: key)
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        try throwUnsupportedNumericTypeError(value: value, forKey: key)
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        try _encodeVarInt(value, forKey: key)
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        try _encodeVarInt(value, forKey: key)
    }
    
    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        try _encode(value, forKey: key)
    }
    
    
    mutating func _encode(_ value: Encodable, forKey key: Key) throws {
        func encodeLengthDelimitedKeyedBytes<S: Collection>(_ sequence: S) where S.Element == UInt8 {
            precondition(sequence.count > 0)
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
            dstBufferRef.value.writeProtoLengthDelimited(sequence)
        }
        
        if GetProtoCodingKind(type(of: value)) == .message {
            context.pushSyntax(value is Proto2Codable ? .proto2 : .proto3)
        }
        defer {
            if GetProtoCodingKind(type(of: value)) == .message {
                context.popSyntax()
            }
        }
        
        if let optionalVal = value as? AnyOptional {
            try _encodeIfPresent(optionalVal.wrappedValue as! Encodable?, forKey: key)
        } else if value is _ProtobufEmbeddedType {
            // We're encoding an embedded type (i.e. a oneof), which means that we completely ignore the key and simply encode the set value as if it were a normal field
            precondition(value is AnyProtobufEnumWithAssociatedValues)
            let possibleKeys: [CodingKey] = (type(of: value) as! AnyProtobufEnumWithAssociatedValues.Type).getCodingKeysType().allCases
            let possibleCodingPaths = possibleKeys.map { self.codingPath.appending($0) }
            context.markAsRequiredOutput(possibleCodingPaths)
            defer {
                context.unmarkAsRequiredOutput(possibleCodingPaths)
            }
            let encoder = _ProtobufferEncoder(codingPath: self.codingPath, dstBufferRef: dstBufferRef, context: context)
            try value.encode(to: encoder)
        } else if value is ProtobufMessage {
            // We're encoding a message. In this case, we need to encode the value length-delimited
            let bufferRef = Box(ByteBuffer())
            let encoder = _ProtobufferEncoder(codingPath: self.codingPath.appending(key), dstBufferRef: bufferRef, context: context)
            try value.encode(to: encoder)
            self.dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: GuessWireType(value)!)
            precondition(self.dstBufferRef.value.writeProtoLengthDelimited(bufferRef.value) > 0)
        } else if let enumVal = value as? AnyProtobufEnum {
            try encode(enumVal.rawValue, forKey: key)
        } else if let string = value as? String {
            try encode(string, forKey: key)
        } else if let bool = value as? Bool {
            try encode(bool, forKey: key)
        } else if let intValue = value as? Int {
            precondition(type(of: value) == Int.self, "\(type(of: value)) | \(value) | \(intValue)")
            try encode(intValue, forKey: key)
        } else if protobufferUnsupportedNumericTypes.contains(type(of: value)) {
            try throwUnsupportedNumericTypeError(value: value, forKey: key)
        } else if let intValue = value as? Int32 {
            precondition(type(of: value) == Int32.self)
            try encode(intValue, forKey: key)
        } else if let intValue = value as? Int64 {
            precondition(type(of: value) == Int64.self)
            try encode(intValue, forKey: key)
        } else if let doubleValue = value as? Double { // TODO do we have to worry about `as?` doing implicit conversions between compatible types here?
            precondition(type(of: value) == Double.self)
            try encode(doubleValue, forKey: key)
        } else if let floatValue = value as? Float {
            precondition(type(of: value) == Float.self)
            try encode(floatValue, forKey: key)
        } else if let array = value as? Array<UInt8>, type(of: value) == Array<UInt8>.self { // We need the additional type(of:) check bc Swift will happily convert empty arrays of type X to empty arrays of type Y :/
            precondition(type(of: value) == Array<UInt8>.self)
            // Protobuffer doesn't have a one-byte type, so this wouldn't be valid anyway, meaning that we can safely interpret an `[UInt8]` as "data"
            //dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
            //dstBufferRef.value.writeProtoLengthDelimited(array)
            encodeLengthDelimitedKeyedBytes(array)
        } else if let data = value as? Data {
            //dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
            //dstBufferRef.value.writeProtoLengthDelimited(data)
            encodeLengthDelimitedKeyedBytes(data)
        } else if let protobufRepeatedTy = value as? ProtobufRepeated {
            let encoder = _ProtobufferEncoder(codingPath: codingPath, dstBufferRef: dstBufferRef, context: context)
            try protobufRepeatedTy.encodeElements(to: encoder, forKey: key)
        } else {
            // We're encoding something that's not a message. In this case we do not apply explicit length-decoding.
            // TODO this is somehwat imperfect. Ideally we'd get rid of the message check above and somehow determine that dynamically!
            // (i.e. determine whether T is a struct like Int (where we don't need to apply additional length-encoding),
            // a struct like String (where the length-encoding would already have happened), or a struct like MyCustomStructWhatever (where
            // we'd need to apply length-encoding)
            // TODO what if `value.encode` doesn't write anything to the buffer? in that case we'd ideally remove the key!!!!!
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: GuessWireType(value)!)
            let encoder = _ProtobufferEncoder(codingPath: self.codingPath.appending(key), dstBufferRef: dstBufferRef, context: context)
            try value.encode(to: encoder)
        }
    }
    
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        //fatalError("Not yet implemented (keyType: \(keyType), key: \(key))")
        return KeyedEncodingContainer(ProtobufferKeyedEncodingContainer<NestedKey>(
            codingPath: codingPath.appending(key),
            dstBufferRef: dstBufferRef,
            context: context
        ))
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError("Not implemented (key: \(key))")
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError()
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        fatalError()
    }
    
    
    // MARK: Optionals
    
    mutating func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
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
    
    mutating func _encodeIfPresent(_ value: Encodable?, forKey key: Key) throws {
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



// MARK: Utilities (TODO move this one to ApodiniUtils? IIRC it's already used somewhere else...

protocol AnyEncodableATRVisitorBase: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = AnyEncodableATRVisitorBase
    associatedtype Input = Encodable
    associatedtype Output

    func callAsFunction<T: Encodable>(_ value: T) -> Output
}

extension AnyEncodableATRVisitorBase {
    @inline(never)
    @_optimize(none)
    func _test() {
        _ = self(12)
    }
}


protocol AnyKeyedEncodingContainerContainerProtocol {
    func encode<T: Encodable>(_ value: T) throws
}


class _KeyedEncodingContainerContainer<Key: CodingKey>: AnyKeyedEncodingContainerContainerProtocol {
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


struct AnyEncodableEncodeIntoKeyedEncodingContainerATRVisitor: AnyEncodableATRVisitorBase {
    let containerContainer: AnyKeyedEncodingContainerContainerProtocol
    
    func callAsFunction<T: Encodable>(_ value: T) -> Result<Void, Error> {
        .init(catching: { try containerContainer.encode(value) })
    }
}
