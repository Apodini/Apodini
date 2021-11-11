import NIO
import ApodiniUtils
import Foundation
@_implementationOnly import Runtime
@_implementationOnly import AssociatedTypeRequirementsVisitor


private let fuckingHellThisIsSoBad_Encode = ThreadSpecificVariable<Box<Encodable.Type>>() // TODO this is unused!


//extension KeyedEncodingContainerProtocol {
//    @_disfavoredOverload
//    func encode(_ value: Encodable, forKey key: Key) throws {
//        precondition(fuckingHellThisIsSoBad.currentValue == nil)
//        fuckingHellThisIsSoBad.currentValue = Box(type)
//        let helperResult = try decode(LKDecodeTypeErasedDecodableTypeHelper.self, forKey: key)
//        precondition(fuckingHellThisIsSoBad.currentValue == nil)
//        return helperResult.value as! Decodable
//    }
//}
//
//
//private struct LKDecodeTypeErasedDecodableTypeHelper: Decodable {
//    let value: Any
//    let originalType: Decodable.Type
//
//    init(value: Any, originalType: Decodable.Type) {
//        self.value = value
//        self.originalType = originalType
//    }
//
//    init(from decoder: Decoder) throws {
//        fatalError("Should be unreachable. If you end up here, that means that you used a decoder which didn't properly handle the \(Self.self) type.")
//    }
//}



///// A protobuffer field (consisting of key and value) that is already encoded into the `bytes` property
//struct _LKAlreadyEncodedProtoField: Encodable {
//    private(set) var bytes = ByteBuffer()
//
//    init(fieldNumber: Int, value: Encodable) throws {
//        guard !LKShouldSkipEncodingBecauseEmptyValue(value) else {
//            return
//        }
//        let dataWriter = _LKProtobufferDataWriter()
//        guard let wireType = LKGuessWireType(value) else {
//            fatalError("Unable to guess wire type for value of type '\(type(of: value))'")
//        }
//        dataWriter.writeKey(forFieldNumber: fieldNumber, wireType: wireType)
//        let encoder = _LKProtobufferEncoder(codingPath: [], dataWriter: dataWriter)
//        try value.encode(to: encoder)
//        bytes.writeImmutableBuffer(dataWriter.buffer)
//    }
//
//    func encode(to encoder: Encoder) throws {
//        fatalError("Don't call directly. The encoder should have a special check for this type.")
//    }
//}


struct LKProtobufferKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let codingPath: [CodingKey]
    let dstBufferRef: Box<ByteBuffer>
    
    init(codingPath: [CodingKey], dstBufferRef: Box<ByteBuffer>) {
        self.codingPath = codingPath
        self.dstBufferRef = dstBufferRef
    }
    
    mutating func encodeNil(forKey key: Key) throws {
        fatalError("Not yet implemented (key: \(key))")
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        if value {
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .varInt)
            dstBufferRef.value.writeProtoVarInt(UInt8(1))
        }
        //fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        guard !value.isEmpty else {
            precondition(LKShouldSkipEncodingBecauseEmptyValue(value) == true)
            // Empty strings are simply omitted from the buffer
            return
        }
        //dataWriter.writeKey(forFieldNumber: key.intValue!, wireType: .lengthDelimited)
        //let len = dataWriter.writeLengthDelimited(value.utf8)
        
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
        dstBufferRef.value.writeProtoLengthDelimited(value.utf8)
        
//        print(len, value.count)
        //fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: Double, forKey key: Key) throws {
        fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: Float, forKey key: Key) throws {
        fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        // TODO should this skip writing zerro values?
        //dataWriter.writeKey(forFieldNumber: key.intValue!, wireType: .varInt) // TODO use the wire type guesser???
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .varInt)
        dstBufferRef.value.writeProtoVarInt(value)
        //fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: Int8, forKey key: Key) throws {
        fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: Int16, forKey key: Key) throws {
        fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: Int32, forKey key: Key) throws {
        // TODO skip zero values?
        dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .varInt)
        dstBufferRef.value.writeProtoVarInt(value)
    }
    
    mutating func encode(_ value: Int64, forKey key: Key) throws {
        fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: UInt, forKey key: Key) throws {
        fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        fatalError("Not yet implemented (value: \(value), key: \(key))")
    }
    
    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
//        print("-[\(Self.self) \(#function)] value: (\(T.self)), key: \(key), T is EmbeddedOneof: \(value is LKProtobufferEmbeddedOneofType)")
        try _encode(value, forKey: key)
    }
    
    
    mutating func _encode(_ value: Encodable, forKey key: Key) throws {
        func encodeLengthDelimitedKeyedBytes<S: Collection>(_ sequence: S) where S.Element == UInt8 {
            precondition(sequence.count > 0)
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: .lengthDelimited)
            dstBufferRef.value.writeProtoLengthDelimited(sequence)
        }
        
        if value is LKProtobufferEmbeddedOneofType {
            // We're encoding an (embedded) oneof type, which means that we completely ignore the key and simply encode the set value as if it were a normal field
            let encoder = _LKProtobufferEncoder(codingPath: self.codingPath, dstBufferRef: dstBufferRef)
            try value.encode(to: encoder)
        } else if value is LKProtobufferMessage {
            // We're encoding a message. In this case, we need to encode the value length-delimited
            let bufferRef = Box(ByteBuffer())
            let encoder = _LKProtobufferEncoder(codingPath: self.codingPath.appending(key), dstBufferRef: bufferRef)
            try value.encode(to: encoder)
            self.dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: LKGuessWireType(value)!)
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
        } else if let repeatedValueCodable = value as? __LKProtobufRepeatedValueCodable {
            let oldWriterIndex = dstBufferRef.value.writerIndex
            let encoder = _LKProtobufferEncoder(codingPath: codingPath, dstBufferRef: dstBufferRef)
            try repeatedValueCodable.encodeElements(to: encoder, forKey: key)
//            let newBuf = dstBufferRef.value.getSlice(at: oldWriterIndex, length: dstBufferRef.value.writerIndex - oldWriterIndex)!
//            print(newBuf)
//            LKNoop()
        } else {
            let result = AnySequenceATRVisitor.run(value: value) { (element: Any) in
                fatalError() // This shouldn't be needed anymore since we're using the RepeatedValueCodable thing above...
                guard let encodable = element as? Encodable else {
                    throw LKProtoEncodingError.other("HMMM \(type(of: element)) \(element)")
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
            dstBufferRef.value.writeProtoKey(forFieldNumber: key.getProtoFieldNumber(), wireType: LKGuessWireType(value)!)
            let encoder = _LKProtobufferEncoder(codingPath: self.codingPath.appending(key), dstBufferRef: dstBufferRef)
            try value.encode(to: encoder)
        }
    }
    
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        //fatalError("Not yet implemented (keyType: \(keyType), key: \(key))")
        return KeyedEncodingContainer(LKProtobufferKeyedEncodingContainer<NestedKey>(codingPath: codingPath.appending(key), dstBufferRef: dstBufferRef))
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError("Not yet implemented (key: \(key))")
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
        //.init(catching: { try encoder.encode(value) })
        //.init(catching: { try containerBox.value.encode(value, forKey: key) })
        .init(catching: { try containerContainer.encode(value) })
    }
}

