import NIO
import Foundation
import ApodiniUtils





public struct ProtobufferDecoder {
    public init() {}
    
    public func decode<T: Decodable>(_: T.Type, from data: Data) throws -> T {
        try decode(T.self, from: ByteBuffer(data: data))
    }
    
    public func decode<T: Decodable>(_: T.Type, from buffer: ByteBuffer) throws -> T {
        // We (currently) don't care about the actual result of the schema, but we want to ensure that the type structure is valid
        // TODO can we somehow use the result from this for the decoding process? prob not, right?
        try validateTypeIsProtoCompatible(T.self)
        let decoder = _ProtobufferDecoder(codingPath: [], buffer: buffer)
        return try T(from: decoder)
    }
    
    public func decode<T: Decodable>(
        _: T.Type,
        from buffer: ByteBuffer,
        atField fieldInfo: ProtoTypeDerivedFromSwift.MessageField
    ) throws -> T {
        // We (currently) don't care about the actual result of the schema, but we want to ensure that the type structure is valid
        // TODO can we somehow use the result from this for the decoding process? prob not, right?
        try validateTypeIsProtoCompatible(T.self)
        let decoder = _ProtobufferDecoder(codingPath: [], buffer: buffer)
        let keyedDecoder = try decoder.container(keyedBy: FixedCodingKey.self)
        return try keyedDecoder.decode(T.self, forKey: .init(intValue: fieldInfo.fieldNumber))
    }
}


class _ProtobufferDecoder: Decoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey : Any]
    let buffer: ByteBuffer
    
    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any] = [:], buffer: ByteBuffer) {
        self.codingPath = codingPath
        self.userInfo = userInfo
        self.buffer = buffer
    }
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        try KeyedDecodingContainer(_LKProtobufferDecoderKeyedDecodingContainer<Key>(
            codingPath: self.codingPath,
            buffer: buffer
        ))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        ProtobufferUnkeyedDecodingContainer(codingPath: codingPath, buffer: buffer)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        // NOTE: We really don't want to end up here, except for cases where the caller knows what it's doing.
        ProtobufferSingleValueDecodingContainer(codingPath: codingPath, buffer: buffer)
    }
    
    func _internalContainer<Key: CodingKey>(keyedBy _: Key.Type) throws -> _LKProtobufferDecoderKeyedDecodingContainer<Key> {
        try _LKProtobufferDecoderKeyedDecodingContainer<Key>(codingPath: codingPath, buffer: buffer)
    }
}


/// Attempts to decode a proto-encoded string
func _LKTryDeocdeProtoString( // TODO make this an extension on ByteBuffer!!!
    in buffer: ByteBuffer,
    fieldValueInfo: ProtobufFieldInfo.ValueInfo,
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
