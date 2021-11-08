import NIO
import ApodiniUtils
import Foundation
@_implementationOnly import AssociatedTypeRequirementsVisitor



///// A type which can be written to a `__LKMutableByteBufferProtocol`
//protocol __LKMutableByteBufferWritable {
//    func write(to dst: inout __LKMutableByteBufferProtocol)
//}
//
//
///// A type to which bytes can be written
//protocol __LKMutableByteBufferProtocol {
//    var capacity: Int { get }
//    mutating func reserve(totalCapacity: Int)
//    mutating func write(_ value: __LKMutableByteBufferWritable)
//}
//
//
//extension ByteBuffer: __LKMutableByteBufferProtocol {
//    mutating func reserve(totalCapacity: Int) {
//        reserveCapacity(totalCapacity)
//    }
//
//    mutating func write(_ value: __LKMutableByteBufferWritable) {
//        value.write(to: &self)
//    }
//}
//
//
//extension Data: __LKMutableByteBufferProtocol {
//
//}


struct LKProtobufferEncoder {
    init() {}
    
    func encode<T: Encodable>(_ value: T) throws -> ByteBuffer {
        var buffer = ByteBuffer()
        try encode(value, into: &buffer)
        return buffer
    }
    
    func encode<T: Encodable>(_ value: T, into buffer: inout ByteBuffer) throws {
        let dstBufferRef = Box(ByteBuffer())
        let encoder = _LKProtobufferEncoder(codingPath: [], userInfo: [:], dstBufferRef: dstBufferRef)
        try value.encode(to: encoder)
        buffer.writeImmutableBuffer(dstBufferRef.value)
    }
}



class _LKProtobufferEncoder: Encoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey : Any]
    let dstBufferRef: Box<ByteBuffer>
    
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any] = [:], dstBufferRef: Box<ByteBuffer>) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.dstBufferRef = dstBufferRef
    }
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(LKProtobufferKeyedEncodingContainer(
            codingPath: codingPath,
            dstBufferRef: dstBufferRef
        ))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        LKProtobufferUnkeyedEncodingContainer(codingPath: codingPath, dstBufferRef: dstBufferRef)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        LKProtobufferSingleValueEncodingContainer(codingPath: codingPath, dstBufferRef: dstBufferRef)
    }
}





/// A type which can be encoded into a `repeated` field.
protocol __LKProtobufRepeatedValueCodable {
    static var elementType: Any.Type { get }
    static var isPacked: Bool { get }
    init<Key: CodingKey>(decodingFrom decoder: Decoder, forKey key: Key, atFields fields: [LKProtobufFieldsMapping.FieldInfo]) throws
    /// Encodes the object's elements into the encoder, keyed by the specified key.
    func encodeElements<Key: CodingKey>(to encoder: Encoder, forKey key: Key) throws
}


extension Array: __LKProtobufRepeatedValueCodable where Element: Codable {
    static var elementType: Any.Type { Element.self }
    
    static var isPacked: Bool {
        switch LKGuessWireType(Element.self)! {
        case .varInt, ._32Bit, ._64Bit:
            return true
        case .lengthDelimited, .startGroup, .endGroup:
            return false
        }
    }
    
    init<Key: CodingKey>(decodingFrom decoder: Decoder, forKey key: Key, atFields fields: [LKProtobufFieldsMapping.FieldInfo]) throws {
        if Self.isPacked {
            fatalError()
        } else {
            let keyedContainer = try (decoder as! _LKProtobufferDecoder)._internalContainer(keyedBy: Key.self)
            //let keyedContainer = decoder.container(keyedBy: Key.self)
            let fields2 = keyedContainer.fields.getAll(forFieldNumber: key.getProtoFieldNumber())
            precondition(fields == fields2)
            self = try fields.map { fieldInfo -> Element in
                try keyedContainer.decode(Element.self, forKey: key, keyOffset: fieldInfo.keyOffset)
            }
        }
    }
    
    func encodeElements<Key: CodingKey>(to encoder: Encoder, forKey key: Key) throws {
        precondition(encoder is _LKProtobufferEncoder)
        if Self.isPacked {
            fatalError()
        } else {
            var keyedContainer = encoder.container(keyedBy: Key.self)
            for element in self {
                try keyedContainer.encode(element, forKey: key)
            }
        }
    }
}


/// A type which is mapped to the `bytes` type
protocol __LKProtobufferBytesMappedType: LKProtobufferPrimitive {}

extension Data: __LKProtobufferBytesMappedType {}
extension Array: __LKProtobufferBytesMappedType, LKProtobufferPrimitive where Element == UInt8 {}



protocol AnySequenceATRVisitorBase: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = AnySequenceATRVisitorBase
    associatedtype Input = Sequence
    associatedtype Output

    func callAsFunction<T: Sequence>(_ value: T) -> Output
}

extension AnySequenceATRVisitorBase {
    @inline(never)
    @_optimize(none)
    func _test() {
        _ = self([123])
    }
}


//protocol AnyKeyedEncodingContainerContainerProtocol {
//    func encode<T: Encodable>(_ value: T) throws
//}
//
//
//class _KeyedEncodingContainerContainer<Key: CodingKey>: AnyKeyedEncodingContainerContainerProtocol {
//    let key: Key
//    var keyedEncodingContainer: KeyedEncodingContainer<Key>
//
//    init(key: Key, keyedEncodingContainer: KeyedEncodingContainer<Key>) {
//        self.key = key
//        self.keyedEncodingContainer = keyedEncodingContainer
//    }
//
//    func encode<T: Encodable>(_ value: T) throws {
//        try keyedEncodingContainer.encode(value, forKey: key)
//    }
//}


struct AnySequenceATRVisitor: AnySequenceATRVisitorBase {
    let block: (Any) throws -> Void
    func callAsFunction<T: Sequence>(_ value: T) -> Result<Void, Error> {
        .init(catching: { try value.forEach(block) })
    }
    
    
    static func run(value: Any, block: (Any) throws -> Void) -> Output? {
        withoutActuallyEscaping(block) { block in
            Self(block: block)(value)
        }
    }
}


