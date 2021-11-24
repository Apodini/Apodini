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


public enum ProtoSyntax { // TODO move this out of this file!
    case proto2
    case proto3
}


public struct ProtobufferEncoder {
    public init() {}
    
    public func encode<T: Encodable>(_ value: T) throws -> ByteBuffer {
        var buffer = ByteBuffer()
        try encode(value, into: &buffer)
        return buffer
    }
    
    public func encode<T: Encodable>(_ value: T, into buffer: inout ByteBuffer) throws {
        let dstBufferRef = Box(ByteBuffer())
        let encoder = _ProtobufferEncoder(
            codingPath: [],
            userInfo: [:],
            dstBufferRef: dstBufferRef,
            context: _EncoderContext()
        )
        if GetProtoCodingKind(type(of: value)) == .message {
            encoder.context.pushSyntax(value is Proto2Codable ? .proto2 : .proto3) // no need to pop here
        }
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
        let encoder = _ProtobufferEncoder(codingPath: [], dstBufferRef: dstBufferRef, context: _EncoderContext())
        if GetProtoCodingKind(type(of: value)) == .message {
            encoder.context.pushSyntax(value is Proto2Codable ? .proto2 : .proto3) // no need to pop here
        }
        var keyedEncoder = encoder.container(keyedBy: FixedCodingKey.self)
        try keyedEncoder.encode(value, forKey: .init(intValue: field.fieldNumber))
        buffer.writeImmutableBuffer(dstBufferRef.value)
    }
}



class _EncoderContext {
    private var syntaxStack = Stack<ProtoSyntax>()
    private var fieldsMarkedAsOptional: Set<[Int]> = [] // int values of the coding path to the field
    
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
    
    func markAsOptional(_ codingPath: [CodingKey]) {
        fieldsMarkedAsOptional.insert(Self.codingPathToInts(codingPath))
    }
    
    func unmarkAsOptional(_ codingPath: [CodingKey]) {
        fieldsMarkedAsOptional.remove(Self.codingPathToInts(codingPath))
    }
    
    func isMarkedAsOptional(_ codingPath: [CodingKey]) -> Bool {
        fieldsMarkedAsOptional.contains(Self.codingPathToInts(codingPath))
    }
    
    
//    func shouldAlwaysIncludeInOutput(_ codingPath: [CodingKey]) -> Bool {
//
//    }
    
    
    private static func codingPathToInts(_ codingPath: [CodingKey]) -> [Int] {
        codingPath.map { $0.getProtoFieldNumber() }
    }
}


class _ProtobufferEncoder: Encoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey : Any]
    let dstBufferRef: Box<ByteBuffer>
    let context: _EncoderContext // One might argue that the dstBuffer should also be in the context, but that wouldnt be a good idea bs we sometimes swap out the dst buffer, but would want to keep using the same context.
    
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any] = [:], dstBufferRef: Box<ByteBuffer>, context: _EncoderContext) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.dstBufferRef = dstBufferRef
        self.context = context
    }
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(ProtobufferKeyedEncodingContainer(
            codingPath: codingPath,
            dstBufferRef: dstBufferRef,
            context: context
        ))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        ProtobufferUnkeyedEncodingContainer(codingPath: codingPath, dstBufferRef: dstBufferRef, context: context)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        ProtobufferSingleValueEncodingContainer(codingPath: codingPath, dstBufferRef: dstBufferRef, context: context)
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


