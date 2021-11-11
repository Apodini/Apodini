import NIO
import Foundation
import ApodiniUtils





public struct LKProtobufferDecoder {
    public init() {}
    
    public func decode<T: Decodable>(_: T.Type, from data: Data) throws -> T {
        try decode(T.self, from: ByteBuffer(data: data))
    }
    
    public func decode<T: Decodable>(_: T.Type, from buffer: ByteBuffer) throws -> T {
        let decoder = _LKProtobufferDecoder(codingPath: [], buffer: buffer)
        return try T(from: decoder)
    }
    
    public func decode<T: Decodable>(
        _: T.Type,
        from buffer: ByteBuffer,
        atField fieldInfo: ProtoTypeDerivedFromSwift.MessageField
    ) throws -> T {
        let decoder = _LKProtobufferDecoder(codingPath: [], buffer: buffer)
        let keyedDecoder = try decoder.container(keyedBy: FakeCodingKey.self)
        return try keyedDecoder.decode(T.self, forKey: .init(intValue: fieldInfo.fieldNumber))
    }
}


// TODO make internal!
class _LKProtobufferDecoder: Decoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey : Any]
    let buffer: ByteBuffer
    
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any] = [:], buffer: ByteBuffer) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.buffer = buffer
    }
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
//        print("-[\(Self.self) \(#function)] \(type)")
        return try KeyedDecodingContainer(_LKProtobufferDecoderKeyedDecodingContainer<Key>(
            codingPath: self.codingPath,
            buffer: buffer
        ))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("Not (yet?) implemented")
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        // NOTE: We really don't want to end up here, except for cases where the caller knows what it's doing.
        return LKProtobufferSingleValueDecodingContainer(codingPath: codingPath, buffer: buffer)
    }
    
    func _internalContainer<Key: CodingKey>(keyedBy _: Key.Type) throws -> _LKProtobufferDecoderKeyedDecodingContainer<Key> {
        return try _LKProtobufferDecoderKeyedDecodingContainer<Key>(codingPath: codingPath, buffer: buffer)
    }
}


/// Attempts to decode a proto-encoded string
func _LKTryDeocdeProtoString(
    in buffer: ByteBuffer,
    fieldValueInfo: LKProtobufFieldsMapping.FieldInfo.ValueInfo,
    fieldValueOffset: Int,
    codingPath: [CodingKey],
    makeDataCorruptedError: (String) -> Error
) throws -> String {
    switch fieldValueInfo {
    case let .lengthDelimited(length, dataOffset):
        guard let bytes = buffer.getBytes(at: fieldValueOffset + dataOffset, length: length) else {
            // NIO says the `getBytes` function only returns nil if the data is not readable
            //throw DecodingError.dataCorruptedError(in: self, debugDescription: "No data")
            throw makeDataCorruptedError("No data")
        }
        if let string = String(bytes: bytes, encoding: .utf8) {
            return string
        } else {
//            throw DecodingError.dataCorruptedError(
//                in: self,
//                debugDescription: "Cannot decode UTF-8 string from bytes \(bytes.description(maxLength: 25))."
//            )
            throw makeDataCorruptedError("Cannot decode UTF-8 string from bytes \(bytes.description(maxLength: 25)).")
        }
    case .varInt, ._32Bit, ._64Bit:
        throw DecodingError.typeMismatch(String.self, DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Cannot decode '\(String.self)' from field with wire type \(fieldValueInfo.wireType). (Expected \(WireType.lengthDelimited) wire type.)",
            underlyingError: nil
        ))
    }
}
