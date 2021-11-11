import NIO
import ApodiniUtils
import Foundation


struct ProtobufferSingleValueEncodingContainer: SingleValueEncodingContainer {
    let codingPath: [CodingKey]
    let dstBufferRef: Box<ByteBuffer>
    
    init(codingPath: [CodingKey], dstBufferRef: Box<ByteBuffer>) {
        self.codingPath = codingPath
        self.dstBufferRef = dstBufferRef
    }
    
    mutating func encodeNil() throws {
        // Nil values simply do not appear at all in the protobuf, so there's nothing to be done here...
    }
    
    mutating func encode(_ value: Bool) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: String) throws {
        precondition(!value.isEmpty) // if a string is empty, we shouldn't end up here in the first place.
        // One issue however is that, even though ideally we'd skip writing the string if it was empty, we can't do that here since in this context we don't
        // QUESTION: Can we safely skip writing the string if it is empty? We don't know whether the field's key has already been written, so if we skip it we might end up w/ a key that's missing a value...
        dstBufferRef.value.writeProtoLengthDelimited(value.utf8)
    }
    
    mutating func encode(_ value: Double) throws {
        dstBufferRef.value.writeProtoDouble(value)
    }
    
    mutating func encode(_ value: Float) throws {
        dstBufferRef.value.writeProtoFloat(value)
    }
    
    mutating func encode(_ value: Int) throws {
        dstBufferRef.value.writeProtoVarInt(value)
    }
    
    mutating func encode(_ value: Int8) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Int16) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Int32) throws {
        dstBufferRef.value.writeProtoVarInt(value)
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
        //if let alreadyEncodedField = value as? _LKAlreadyEncodedProtoField {
        //    dataWriter.write(alreadyEncodedField.bytes)
        //} else {
            fatalError("Not yet implemented (T: \(T.self), value: \(value))")
        //}
    }
    
}


extension ByteBuffer {
    func lk_getAllBytes() -> [UInt8] {
        getBytes(at: 0, length: writerIndex) ?? []
    }
}
