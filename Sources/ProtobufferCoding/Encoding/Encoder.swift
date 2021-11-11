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


public struct ProtobufferEncoder {
    public init() {}
    
    public func encode<T: Encodable>(_ value: T) throws -> ByteBuffer {
        var buffer = ByteBuffer()
        try encode(value, into: &buffer)
        return buffer
    }
    
    public func encode<T: Encodable>(_ value: T, into buffer: inout ByteBuffer) throws {
        let dstBufferRef = Box(ByteBuffer())
        let encoder = _ProtobufferEncoder(codingPath: [], userInfo: [:], dstBufferRef: dstBufferRef)
        try value.encode(to: encoder)
        buffer.writeImmutableBuffer(dstBufferRef.value)
    }
    
    public func encode<T: Encodable>(_ value: T, asField field: ProtoTypeDerivedFromSwift.MessageField) throws -> ByteBuffer {
        var buffer = ByteBuffer()
        try encode(value, into: &buffer, asField: field)
        return buffer
    }
    
    public func encode<T: Encodable>(
        _ value: T,
        into buffer: inout ByteBuffer,
        asField field: ProtoTypeDerivedFromSwift.MessageField
    ) throws {
        let dstBufferRef = Box(ByteBuffer())
        let encoder = _ProtobufferEncoder(codingPath: [], dstBufferRef: dstBufferRef)
        var keyedEncoder = encoder.container(keyedBy: FixedCodingKey.self)
        try keyedEncoder.encode(value, forKey: .init(intValue: field.fieldNumber))
        buffer.writeImmutableBuffer(dstBufferRef.value)
    }
}



class _ProtobufferEncoder: Encoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey : Any]
    let dstBufferRef: Box<ByteBuffer>
    
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any] = [:], dstBufferRef: Box<ByteBuffer>) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.dstBufferRef = dstBufferRef
    }
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(ProtobufferKeyedEncodingContainer(
            codingPath: codingPath,
            dstBufferRef: dstBufferRef
        ))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        ProtobufferUnkeyedEncodingContainer(codingPath: codingPath, dstBufferRef: dstBufferRef)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        ProtobufferSingleValueEncodingContainer(codingPath: codingPath, dstBufferRef: dstBufferRef)
    }
}





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


