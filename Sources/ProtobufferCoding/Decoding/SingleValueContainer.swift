import NIO
import Foundation


/// A single-value decoding container, which supports decoding a single unkeyed value.
struct ProtobufferSingleValueDecodingContainer: SingleValueDecodingContainer {
    let codingPath: [CodingKey]
    private let buffer: ByteBuffer
    private let fieldInfo: ProtobufFieldInfo?
    
    /// The buffer should point to the start of a key-value pair // TODO outdated comment, in reality the buffer usually points to the value, and we can ignore the key.
    init(codingPath: [CodingKey], buffer: ByteBuffer) {
        self.codingPath = codingPath
        self.buffer = buffer
        //self.fieldInfo = (try? ProtobufMessageLayoutDecoder.getFields(in: buffer))?.allFields.first { $0.keyOffset == buffer.readerIndex }
        self.fieldInfo = nil
        precondition(fieldInfo == nil)
    }
    
    
    private func assertWireTypeIfPresent(_ expectedValue: WireType) {
        if let wireType = fieldInfo?.wireType {
            precondition(wireType == expectedValue)
        }
    }
    
    
    func decodeNil() -> Bool {
        fatalError("TODO how do we want to handle this?")
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        fatalError("Not implemented (type: \(type))")
    }
    
    func decode(_ type: String.Type) throws -> String {
        assertWireTypeIfPresent(.lengthDelimited)
        // NOTE normally, we'd return empty strings in case a field is not present.
        // That doesn't apply, though, in this case, since the SingleValueDecoder only ever gets used
        // in cases where we already have data and just need to pipe it through e.g. a String's `init(from:)`.
        // (At least, that's how it is intended to be used. Anything else is UB.)
//        switch fieldInfo.valueInfo {
//        case ._32Bit, ._64Bit, .varInt:
//            throw DecodingError.typeMismatch(type, DecodingError.Context(
//                codingPath: codingPath,
//                debugDescription: "Cannot decode '\(type)' from field with wire type \(fieldInfo.wireType). (Expected \(WireType.lengthDelimited) wire type.)",
//                underlyingError: nil
//            ))
//        case let .lengthDelimited(length, dataOffset):
//            guard let bytes = buffer.getBytes(at: fieldInfo.valueOffset + dataOffset, length: length) else {
//                // NIO says the `getBytes` function only returns nil if the data is not readable
//                throw DecodingError.dataCorruptedError(in: self, debugDescription: "No data")
//            }
//            if let string = String(bytes: bytes, encoding: .utf8) {
//                return string
//            } else {
//                throw DecodingError.dataCorruptedError(
//                    in: self,
//                    debugDescription: "Cannot decode UTF-8 string from bytes \(bytes.description(maxLength: 25))."
//                )
//            }
//        }
        
        if let fieldInfo = fieldInfo {
            return try _LKTryDeocdeProtoString(
                in: buffer,
                fieldValueInfo: fieldInfo.valueInfo,
                fieldValueOffset: fieldInfo.valueOffset,
                codingPath: codingPath,
                makeDataCorruptedError: { errorDesc in
                    DecodingError.dataCorruptedError(in: self, debugDescription: errorDesc)
                }
            )
        } else {
            // This is somewhat annoying but basically the thing is that if we don't have a fieldInfo object we'll just have to make a guess that this is in fact a string and that the first byte is the varInt length
            var bufferCopy = buffer
            let length = Int(try bufferCopy.readVarInt())
            return try _LKTryDeocdeProtoString(
                in: buffer,
                fieldValueInfo: .lengthDelimited(dataLength: length, dataOffset: bufferCopy.readerIndex - buffer.readerIndex),
                fieldValueOffset: buffer.readerIndex,
                codingPath: codingPath,
                makeDataCorruptedError: { errorDesc in
                    DecodingError.dataCorruptedError(in: self, debugDescription: errorDesc)
                }
            )
        }
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        assertWireTypeIfPresent(._64Bit)
        return try buffer.getProtoDouble(at: fieldInfo?.valueOffset ?? buffer.readerIndex)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        assertWireTypeIfPresent(._32Bit)
        return try buffer.getProtoFloat(at: fieldInfo?.valueOffset ?? buffer.readerIndex)
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        assertWireTypeIfPresent(.varInt)
        return Int(bitPattern: UInt(try buffer.getVarInt(at: fieldInfo?.valueOffset ?? buffer.readerIndex)))
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        fatalError("Not implemented (type: \(type))")
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        fatalError("Not implemented (type: \(type))")
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        try decodeVarInt(type)
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        fatalError("Not yet implemented (type: \(type))")
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        fatalError("Not yet implemented (type: \(type))")
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        fatalError("Not implemented (type: \(type))")
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        fatalError("Not implemented (type: \(type))")
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        fatalError("Not yet implemented (type: \(type))")
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        fatalError("Not yet implemented (type: \(type))")
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        fatalError("Not implemented (type: \(type))")
    }
    
    
    private func decodeVarInt<T: BinaryInteger>(_: T.Type) throws -> T {
        assertWireTypeIfPresent(.varInt)
        return numericCast(try buffer.getVarInt(at: fieldInfo?.valueOffset ?? buffer.readerIndex))
    }
}
