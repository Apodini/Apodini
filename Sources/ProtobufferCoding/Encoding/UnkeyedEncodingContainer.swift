import NIO
import ApodiniUtils
import Foundation

struct ProtobufferUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    let codingPath: [CodingKey]
    let dstBufferRef: Box<ByteBuffer>
    let context: _EncoderContext
    
    var count: Int {
        // TODO when does this get called? Who calls this?
        // Should it represent the number of elements that have been encoded so far? or the expected number?
        fatalError()
    }
    
    init(codingPath: [CodingKey], dstBufferRef: Box<ByteBuffer>, context: _EncoderContext) {
        self.codingPath = codingPath
        self.dstBufferRef = dstBufferRef
        self.context = context
    }
    
    mutating func encodeNil() throws {
        fatalError()
    }
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        fatalError("Not implemented (keyType: \(keyType))")
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Not implemented")
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError()
    }
    
    mutating func encode(_ value: Bool) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: String) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Double) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Float) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Int) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Int8) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Int16) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Int32) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Int64) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: UInt) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: UInt8) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: UInt16) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: UInt32) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: UInt64) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        // TODO do we need to do special checks for certain types here?
        let encoder = _ProtobufferEncoder(codingPath: codingPath, dstBufferRef: dstBufferRef, context: context)
        try value.encode(to: encoder)
    }
}
