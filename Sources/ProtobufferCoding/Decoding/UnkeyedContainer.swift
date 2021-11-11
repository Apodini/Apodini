import NIO
import ApodiniUtils
import Foundation


struct ProtobufferUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    let codingPath: [CodingKey]
    let count: Int? = nil // TODO are there instances where we know the number of elements?
    var isAtEnd: Bool { buffer.readableBytes == 0 }
    private(set) var currentIndex: Int = 0
    private var buffer: ByteBuffer
    
    init(codingPath: [CodingKey], buffer: ByteBuffer) {
        self.codingPath = codingPath
        self.buffer = buffer
    }
    
    
    mutating func decodeNil() throws -> Bool {
        fatalError("Not implemented")
    }
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        fatalError("Not implemented")
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("Not implemented")
    }
    
    mutating func superDecoder() throws -> Decoder {
        fatalError("Not implemented")
    }
    
    
    mutating func decode(_ type: String.Type) throws -> String {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        fatalError("Not implemented")
    }
    
    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        fatalError("Not implemented")
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        fatalError("Not implemented")
    }
}
