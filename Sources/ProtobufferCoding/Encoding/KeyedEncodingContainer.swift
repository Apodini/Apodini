import NIO
import ApodiniUtils
import Foundation
@_implementationOnly import Runtime
@_implementationOnly import AssociatedTypeRequirementsVisitor


struct ProtobufferKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let codingPath: [CodingKey]
    let dstBufferRef: Box<ByteBuffer>
    
    init(codingPath: [CodingKey], dstBufferRef: Box<ByteBuffer>) {
        self.codingPath = codingPath
        self.dstBufferRef = dstBufferRef
    }
    
    mutating func encodeNil(forKey key: Key) throws {
        fatalError("Not implemented (key: \(key))")
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        if value {
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .varInt)
            dstBufferRef.value.writeProtoVarInt(UInt8(1))
        }
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        guard !value.isEmpty else {
            // Empty strings are simply omitted from the buffer
            return
        }
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
        dstBufferRef.value.writeProtoLengthDelimited(value.utf8)
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        fatalError("Not implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        fatalError("Not implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        // TODO should this skip writing zerro values?
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .varInt)
        dstBufferRef.value.writeProtoVarInt(value)
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        fatalError("Not implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        fatalError("Not implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        // TODO skip zero values?
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .varInt)
        dstBufferRef.value.writeProtoVarInt(value)
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        fatalError("Not implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        fatalError("Not implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        fatalError("Not implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        fatalError("Not implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        fatalError("Not implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        fatalError("Not implemented (value: \(value), key: \(key))")
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
        
        if value is _ProtobufEmbeddedType {
            // We're encoding an embedded type (i.e. a oneof), which means that we completely ignore the key and simply encode the set value as if it were a normal field
            let encoder = _ProtobufferEncoder(codingPath: self.codingPath, dstBufferRef: dstBufferRef)
            try value.encode(to: encoder)
        } else if value is ProtobufMessage {
            // We're encoding a message. In this case, we need to encode the value length-delimited
            let bufferRef = Box(ByteBuffer())
            let encoder = _ProtobufferEncoder(codingPath: self.codingPath.appending(key), dstBufferRef: bufferRef)
            try value.encode(to: encoder)
            self.dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: GuessWireType(value)!)
            precondition(self.dstBufferRef.value.writeProtoLengthDelimited(bufferRef.value) > 0)
        } else if let string = value as? String {
            try encode(string, forKey: key)
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
            let oldWriterIndex = dstBufferRef.value.writerIndex
            let encoder = _ProtobufferEncoder(codingPath: codingPath, dstBufferRef: dstBufferRef)
            try protobufRepeatedTy.encodeElements(to: encoder, forKey: key)
        } else {
            let result = AnySequenceATRVisitor.run(value: value) { (element: Any) in
                fatalError() // This shouldn't be needed anymore since we're using the RepeatedValueCodable thing above...
                guard let encodable = element as? Encodable else {
                    throw ProtoEncodingError.other("HMMM \(type(of: element)) \(element)")
                }
                try self._encode(encodable, forKey: key)
            }
            switch result {
            case nil:
                // Type is not a sequence...
                // This is the only case we want to continue to after the switch
                break
            case .success:
                // Type is a sequence, and we successfully managed to encode all of the sequence's elements into the buffer
                return
            case .failure(let error):
                // Type is a sequence, but we encountered an error trying to encode the sequence's elements into the buffer
                throw error
            }
            
            // We're encoding something that's not a message. In this case we do not apply explicit length-decoding.
            // TODO this is somehwat imperfect. Ideally we'd get rid of the message check above and somehow determine that dynamically!
            // (i.e. determine whether T is a struct like Int (where we don't need to apply additional length-encoding),
            // a struct like String (where the length-encoding would already have happened), or a struct like MyCustomStructWhatever (where
            // we'd need to apply length-encoding)
            // TODO what if `value.encode` doesn't write anything to the buffer? in that case we'd ideally remove the key!!!!!
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: GuessWireType(value)!)
            let encoder = _ProtobufferEncoder(codingPath: self.codingPath.appending(key), dstBufferRef: dstBufferRef)
            try value.encode(to: encoder)
        }
    }
    
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        //fatalError("Not yet implemented (keyType: \(keyType), key: \(key))")
        return KeyedEncodingContainer(ProtobufferKeyedEncodingContainer<NestedKey>(
            codingPath: codingPath.appending(key),
            dstBufferRef: dstBufferRef
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
