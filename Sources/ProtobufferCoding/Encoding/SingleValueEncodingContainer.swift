import NIO
import ApodiniUtils
import Foundation


struct ProtobufferSingleValueEncodingContainer: SingleValueEncodingContainer {
    let codingPath: [CodingKey]
    let dstBufferRef: Box<ByteBuffer>
    let context: _EncoderContext
    
    init(codingPath: [CodingKey], dstBufferRef: Box<ByteBuffer>, context: _EncoderContext) {
        self.codingPath = codingPath
        self.dstBufferRef = dstBufferRef
        self.context = context
    }
    
    mutating func encodeNil() throws {
        // Nil values simply do not appear at all in the protobuf, so there's nothing to be done here...
    }
    
    mutating func encode(_ value: Bool) throws {
        dstBufferRef.value.writeProtoVarInt(value ? 1 : 0)
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
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath)
    }
    
    mutating func encode(_ value: Int16) throws {
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath)
    }
    
    mutating func encode(_ value: Int32) throws {
        dstBufferRef.value.writeProtoVarInt(value)
    }
    
    mutating func encode(_ value: Int64) throws {
        dstBufferRef.value.writeProtoVarInt(value)
    }
    
    mutating func encode(_ value: UInt) throws {
        dstBufferRef.value.writeProtoVarInt(value)
    }
    
    mutating func encode(_ value: UInt8) throws {
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath)
    }
    
    mutating func encode(_ value: UInt16) throws {
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath)
    }
    
    mutating func encode(_ value: UInt32) throws {
        dstBufferRef.value.writeProtoVarInt(value)
    }
    
    mutating func encode(_ value: UInt64) throws {
        dstBufferRef.value.writeProtoVarInt(value)
    }
    
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        if let stringVal = value as? String {
            try encode(stringVal)
        } else if let boolVal = value as? Bool {
            try encode(boolVal)
        } else if protobufferUnsupportedNumericTypes.contains(type(of: value)) {
            try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath)
        } else if value as? ProtobufRepeated != nil {
            throw EncodingError.invalidValue(value, .init(
                codingPath: codingPath,
                debugDescription: "Cannot encode repeated value into \(Self.self)",
                underlyingError: nil
            ))
        } else if let i32Val = value as? Int32 {
            try encode(i32Val)
        } else if let u32Val = value as? UInt32 {
            try encode(u32Val)
        } else if let i64Val = value as? Int64 {
            try encode(i64Val)
        } else if let u64Val = value as? UInt64 {
            try encode(u64Val)
        } else if let intVal = value as? Int {
            try encode(intVal)
        } else if let uintVal = value as? UInt {
            try encode(uintVal)
        } else {
            fatalError("Not yet implemented (T: \(T.self), value: \(value))")
        }
    }
}


extension ByteBuffer {
    public func lk_getAllBytes() -> [UInt8] {
        getBytes(at: 0, length: writerIndex)!
    }
}
