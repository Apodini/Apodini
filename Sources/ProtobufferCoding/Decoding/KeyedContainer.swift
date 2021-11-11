import NIO
import Foundation
import ApodiniUtils
import ProtobufferCoding_old


private let fuckingHellThisIsSoBad = ThreadSpecificVariable<Box<Decodable.Type>>()


extension KeyedDecodingContainerProtocol {
    @_disfavoredOverload
    func decode(_ type: Decodable.Type, forKey key: Key) throws -> Decodable {
        precondition(fuckingHellThisIsSoBad.currentValue == nil)
        fuckingHellThisIsSoBad.currentValue = Box(type)
        let helperResult = try decode(LKDecodeTypeErasedDecodableTypeHelper.self, forKey: key)
        precondition(fuckingHellThisIsSoBad.currentValue == nil)
        return helperResult.value as! Decodable
    }
}


private struct LKDecodeTypeErasedDecodableTypeHelper: Decodable {
    let value: Any
    let originalType: Decodable.Type
    
    init(value: Any, originalType: Decodable.Type) {
        self.value = value
        self.originalType = originalType
    }
    
    init(from decoder: Decoder) throws {
        fatalError("Should be unreachable. If you end up here, that means that you used a decoder which didn't properly handle the \(Self.self) type.")
    }
}


struct _LKProtobufferDecoderKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let codingPath: [CodingKey]
    private let buffer: ByteBuffer
    let fields: ProtobufFieldsMapping
    
    var allKeys: [Key] {
        fatalError()
    }
    
    init(codingPath: [CodingKey], buffer: ByteBuffer) throws {
        self.codingPath = codingPath
        self.buffer = buffer
        self.fields = try ProtobufMessageLayoutDecoder.getFields(in: buffer)
    }
    
    /// - Note: This will produce unexpected results for some situations, e.g. in cases there the absence of a value indicates the presence of an empty value.
    func contains(_ key: Key) -> Bool {
        return fields.contains(fieldNumber: key.getProtoFieldNumber())
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        // proto3 doesn't really have nullable fields, so we just always return false...
        return false
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let fieldInfo = fields.getLast(forFieldNumber: key.getProtoFieldNumber()) else {
            return false
        }
        let intValue = buffer.getInteger(at: fieldInfo.valueOffset, as: UInt8.self)!
        switch intValue {
        case 0:
            return false
        case 1:
            return true
        default:
            fatalError("Decoded invalid int value for bool: \(intValue)")
        }
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let fieldInfo = fields.getLast(forFieldNumber: key.getProtoFieldNumber()) else {
            return ""
        }
        return try _LKTryDeocdeProtoString(
            in: buffer,
            fieldValueInfo: fieldInfo.valueInfo,
            fieldValueOffset: fieldInfo.valueOffset,
            codingPath: codingPath,
            makeDataCorruptedError: { errorDesc in
                DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: errorDesc)
            }
        )
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        fatalError("Not implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        fatalError("Not implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let fieldInfo = fields.getLast(forFieldNumber: key.getProtoFieldNumber()) else {
            return 0 // TODO is this the right approach?
        }
        return Int(try buffer.getVarInt(at: fieldInfo.valueOffset))
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        fatalError("Not implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        fatalError("Not implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let fieldInfo = fields.getLast(forFieldNumber: key.getProtoFieldNumber()) else {
            return 0
        }
        return Int32(try buffer.getVarInt(at: fieldInfo.valueOffset))
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        fatalError("Not implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        fatalError("Not implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        fatalError("Not implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        fatalError("Not implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        fatalError("Not implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        fatalError("Not implemented (type: \(type), key: \(key))")
    }
    
    //@_disfavoredOverload
    func decode<T: Decodable>(_: T.Type, forKey key: Key) throws -> T {
        try _decode(T.self, forKey: key, keyOffset: nil) as! T
    }
    
    
    //@_disfavoredOverload
    func decode<T: Decodable>(_: T.Type, forKey key: Key, keyOffset: Int?) throws -> T {
        try _decode(T.self, forKey: key, keyOffset: keyOffset) as! T
    }
    
    
    
    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        fatalError("Not implemented (type: \(type), key: \(key))")
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        fatalError("Not implemented (key: \(key))")
    }
    
    func superDecoder() throws -> Decoder {
        fatalError("Not implemented")
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        fatalError("Not implemented (key: \(key))")
    }
    
    
    // MARK: the type stuff
    
    private func getFieldInfoAndBytes(forKey key: Key, atOffset keyOffset: Int?) throws -> (fieldInfo: ProtobufFieldInfo, fieldBytes: ByteBuffer) {
        let fieldNumber = key.getProtoFieldNumber()
        guard fieldNumber > 0 else {
            fatalError()
        }
        let fieldInfo: ProtobufFieldInfo?
        if let keyOffset = keyOffset {
            fieldInfo = fields.allFields.first { $0.tag == fieldNumber && $0.keyOffset == keyOffset }
        } else {
            fieldInfo = fields.getLast(forFieldNumber: fieldNumber)
        }
        guard let fieldInfo = fieldInfo else {
            fatalError()
        }
        return (fieldInfo, buffer.getSlice(at: fieldInfo.keyOffset, length: fieldInfo.fieldLength)!)
    }
    
    
    private func getFieldInfoAndValueBytes(
        forKey key: Key,
        atOffset keyOffset: Int?
    ) throws -> (fieldInfo: ProtobufFieldInfo, valueBytes: ByteBuffer) {
        let (fieldInfo, fieldBytes) = try getFieldInfoAndBytes(forKey: key, atOffset: keyOffset)
        let keyLength = fieldInfo.valueOffset - fieldInfo.keyOffset
        return (fieldInfo, fieldBytes.getSlice(at: keyLength, length: fieldBytes.readableBytes - keyLength)!)
    }
    
    
    func _decode(_ type: Decodable.Type, forKey key: Key, keyOffset: Int?) throws -> Any {
        //try decode(T.self, for) as! T
        if type == LKDecodeTypeErasedDecodableTypeHelper.self {
        //if T.self is LKDecodeTypeErasedDecodableTypeHelper.Type {
            //precondition(type == LKDecodeTypeErasedDecodableTypeHelper.self)
            let type = fuckingHellThisIsSoBad.currentValue!.value
            fuckingHellThisIsSoBad.currentValue = nil
            return LKDecodeTypeErasedDecodableTypeHelper(
                value: try _decode(type, forKey: key, keyOffset: keyOffset), // TODO this decode call used to go to the old implementation below (commented out)
                originalType: type
            )
        } else if (type as? _ProtobufEmbeddedType.Type) != nil {
            // We're asked to decode an embedded type (currently only oneof, as far as i'm aware),
            // which means what we need to ignore the coding key.
            // Note: since oneofs can't be repeated (TODO check!) we can ignore a potentially specified offset here
            precondition(keyOffset == nil)
            return try type.init(from: _ProtobufferDecoder(codingPath: codingPath, buffer: buffer))
        } else if ((type as? ProtobufMessage.Type) != nil) || (type == Array<UInt8>.self) || (type == Data.self) {
            // We're asked to decode an embedded message, or a lump of bytes.
            // Embedded messages are essentially the same as normal key-value pairs, but we have to drop the preceding length delimiter first.
            // Same goes for byte fields, the only difference here is that we don't have to decode them into a concrete type.
            let (fieldInfo, valueBytes) = try getFieldInfoAndValueBytes(forKey: key, atOffset: keyOffset)
            precondition(fieldInfo.wireType == .lengthDelimited)
            var adjustedValueBytes = valueBytes
            let length = Int(try adjustedValueBytes.readVarInt())
            precondition(adjustedValueBytes.readableBytes >= length)
            precondition(fieldInfo.valueInfo == .lengthDelimited(dataLength: length, dataOffset: adjustedValueBytes.readerIndex - valueBytes.readerIndex))
            if (type as? ProtobufMessage.Type) != nil {
                return try type.init(from: _ProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: adjustedValueBytes))
            } else if type == Array<UInt8>.self {
                return Array<UInt8>(buffer: adjustedValueBytes)
            } else if type == Data.self {
                return Data(buffer: adjustedValueBytes)
            } else {
                // unreacahable
                fatalError()
            }
        } else if let protobufRepeatedTy = type as? ProtobufRepeated.Type {
            let decoder = _ProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: buffer)
            let retval = try protobufRepeatedTy.init(
                decodingFrom: decoder,
                forKey: key,
                atFields: fields.getAll(forFieldNumber: key.getProtoFieldNumber())
            )
            return retval
        } else {
            let (fieldInfo, valueBytes) = try getFieldInfoAndValueBytes(forKey: key, atOffset: keyOffset)
            let _A = try type.init(from: _ProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: valueBytes))
            return _A
        }
        
//        let (fieldInfo, fieldBytes) = try getFieldInfoAndBytes(forKey: key, atOffset: keyOffset)
//        print(fieldInfo.valueOffset, fieldInfo.keyOffset)
//        let decoder = _LKProtobufferDecoder(
//            codingPath: self.codingPath.appending(key as! Key),
//            userInfo: [:],
//            //buffer: fieldBytes.getSlice(at: fieldInfo.valueOffset - fieldInfo.keyOffset, length: fieldBytes.readableBytes - (fieldInfo.valueOffset - fieldInfo.keyOffset))!
//            buffer: fieldBytes
//        )
//        // TODO do we need special checks for different types here?
//        let value = try type.init(from: decoder)
//        return value
    }
}
