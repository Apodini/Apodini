import NIO
import ApodiniUtils
import Foundation

struct LKProtobufferUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    let codingPath: [CodingKey]
    let dstBufferRef: Box<ByteBuffer>
    var count: Int {
        // TODO when does this get called? Who calls this?
        // Should it represent the number of elements that have been encoded so far? or the expected number?
        fatalError()
    }
    
    init(codingPath: [CodingKey], dstBufferRef: Box<ByteBuffer>) {
        self.codingPath = codingPath
        self.dstBufferRef = dstBufferRef
    }
    
    mutating func encodeNil() throws {
        fatalError()
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("Not yet implemented (keyType: \(keyType))")
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Not yet implemented")
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError()
    }
    
    mutating func encode(_ value: Bool) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: String) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: Double) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: Float) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: Int) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: Int8) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: Int16) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: Int32) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: Int64) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: UInt) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: UInt8) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: UInt16) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: UInt32) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode(_ value: UInt64) throws {
        fatalError("Not yet implemented")
    }
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        // TODO do we need to do special checks for certain types here?
        let encoder = _LKProtobufferEncoder(codingPath: codingPath, dstBufferRef: dstBufferRef)
        try value.encode(to: encoder)
        //fatalError("Not yet implemented (T: \(T.self), value: \(value)")
    }
}



func LKNoop() {}
