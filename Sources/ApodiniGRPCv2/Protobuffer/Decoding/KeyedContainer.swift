import NIO
import Foundation
import ApodiniUtils
import ProtobufferCoding


private let fuckingHellThisIsSoBad = ThreadSpecificVariable<Box<Decodable.Type>>()


extension KeyedDecodingContainerProtocol {
    @_disfavoredOverload
    func decode(_ type: Decodable.Type, forKey key: Key) throws -> Decodable {
        //fatalError("\(#function) not implemented in '\(Self.self)'")
        precondition(fuckingHellThisIsSoBad.currentValue == nil)
        //fuckingHellThisIsSoBad.currentValue!.value = type
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



struct FakeCodingKey: CodingKey { // TODO better name
    /// Guaranteed to be non-nil, but has to be nullable to satisfy the `CodingKey` protocol
    let intValue: Int?
    
    init(intValue: Int) {
        self.intValue = intValue
    }
    
    init?(stringValue: String) {
        fatalError()
    }
    var stringValue: String {
        fatalError()
    }
}


struct _LKProtobufferDecoderKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let codingPath: [CodingKey]
    private let buffer: ByteBuffer
    let fields: LKProtobufFieldsMapping
    
    var allKeys: [Key] {
        fatalError()
    }
    
    init(codingPath: [CodingKey], buffer: ByteBuffer) throws {
        self.codingPath = codingPath
        self.buffer = buffer
        self.fields = try ProtobufMessageLayoutDecoder.getFields(in: buffer)
    }
    
    /// - Note: This will produce unexpected results for some situatioins, e.g. in cases there the absence of a value indicates the presence of an empty value.
    func contains(_ key: Key) -> Bool {
//        guard let intValue = key.intValue else {
//            // TODO or just return false? If there's no int key, we can't index into the buffer, therefore the buffer doesn't contain the field.
//            fatalError("CodingKey \(key) has no int value. Required for decoding protobuf messages")
//        }
        //precondition(try! key.intValue! == key.defaultProtoRawValue())
        return fields.contains(fieldNumber: key.getProtoFieldNumber())
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        // proto3 doesn't have nullable fields, so we just always return false...
        return false
//        // Note: this might pruduce unexpected results when called for
//        fatalError("Not yet implemented (key: \(key))")
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
//        guard let fieldNumber = key.intValue else {
//            throw DecodingError
//        }
//        fatalError("Not yet implemented")
        //precondition(try! key.intValue! == key.defaultProtoRawValue())
        guard let fieldInfo = fields.getLast(forFieldNumber: key.getProtoFieldNumber()) else {
            return ""
        }
//        switch fieldInfo.valueInfo {
//        case let .lengthDelimited(length, dataOffset):
//            guard let bytes = buffer.getBytes(at: fieldInfo.valueOffset + dataOffset, length: length) else {
//                // NIO says the `getBytes` function only returns nil if the data is not readable
//                throw DecodingError.dataCorruptedError(in: self, debugDescription: "No data")
//            }
//            if let string = String(bytes: bytes, encoding: .utf8) {
//                return string
//            } else {
//                throw DecodingError.dataCorruptedError(
//                    forKey: key,
//                    in: self,
//                    debugDescription: "Cannot decode UTF-8 string from bytes \(bytes.description(maxLength: 25))."
//                )
//            }
////        case let .lengthDelimited(length, dataOffset):
////            if let string = buffer.getString(at: fieldInfo.valueOffset + dataOffset, length: length, encoding: .utf8) {
////                return string
////            } else {
////                throw DecodingError.dataCorruptedError(
////                    forKey: key,
////                    in: self,
////                    debugDescription: "Unable to decode a UTF-8 string. (Underlying bytes: \(valueBuffer.getBytes(at: 0, length: min(25, valueBuffer.readableBytes)) as Any))"
////                )
////            }
//        case .varInt, ._32Bit, ._64Bit:
//            throw DecodingError.typeMismatch(String.self, DecodingError.Context(
//                codingPath: codingPath,
//                debugDescription: "Cannot read \(String.self) from field with wire type \(fieldInfo.wireType)",
//                underlyingError: nil
//            ))
//        }
        return try _LKTryDeocdeProtoString(
            in: buffer,
            fieldValueInfo: fieldInfo.valueInfo,
            fieldValueOffset: fieldInfo.valueOffset,
            codingPath: codingPath,
            makeDataCorruptedError: { errorDesc in
                DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: errorDesc)
            }
        )
//        return try _LKTryDeocdeProtoString(in: buffer, fieldInfo: fieldInfo, codingPath: codingPath, makeDataCorruptedError: { errorDescription in
//            DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: errorDescription)
//        })
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        fatalError("Not yet implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        fatalError("Not yet implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let fieldInfo = fields.getLast(forFieldNumber: key.getProtoFieldNumber()) else {
            return 0 // TODO is this the right approach?
        }
        return Int(try buffer.getVarInt(at: fieldInfo.valueOffset))
        fatalError("Not yet implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        fatalError("Not yet implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        fatalError("Not yet implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let fieldInfo = fields.getLast(forFieldNumber: key.getProtoFieldNumber()) else {
            return 0
        }
        return Int32(try buffer.getVarInt(at: fieldInfo.valueOffset))
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        fatalError("Not yet implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        fatalError("Not yet implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        fatalError("Not yet implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        fatalError("Not yet implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        fatalError("Not yet implemented (type: \(type), key: \(key))")
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        fatalError("Not yet implemented (type: \(type), key: \(key))")
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
        fatalError("Not yet implemented (type: \(type), key: \(key))")
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        fatalError("Not yet implemented (key: \(key))")
    }
    
    func superDecoder() throws -> Decoder {
        fatalError("Not yet implemented")
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        fatalError("Not yet implemented (key: \(key))")
    }
    
    
    // MARK: the type stuff
    
    private func getFieldInfoAndBytes(forKey key: Any, atOffset keyOffset: Int?) throws -> (fieldInfo: LKProtobufFieldsMapping.FieldInfo, fieldBytes: ByteBuffer) {
        guard let key = key as? Key else {
            fatalError() // TODO throw!
        }
//        guard let fieldNumber = key.intValue else {
//            fatalError()
//        }
        let fieldNumber = key.getProtoFieldNumber()
        //precondition(try! key.intValue! == key.defaultProtoRawValue())
        guard fieldNumber > 0 else {
            fatalError()
        }
        let fieldInfo: LKProtobufFieldsMapping.FieldInfo?
        if let keyOffset = keyOffset {
            fieldInfo = fields.allFields.first { $0.tag == fieldNumber && $0.keyOffset == keyOffset }
        } else {
            fieldInfo = fields.getLast(forFieldNumber: fieldNumber)
        }
        //guard let fieldInfo = fields.getLast(forFieldNumber: fieldNumber) else {
        //    fatalError()
        //}
        guard let fieldInfo = fieldInfo else {
            fatalError()
        }
        return (fieldInfo, buffer.getSlice(at: fieldInfo.keyOffset, length: fieldInfo.fieldLength)!)
    }
    
    private func getFieldInfoAndValueBytes(
        forKey key: Any,
        atOffset keyOffset: Int?
    ) throws -> (fieldInfo: LKProtobufFieldsMapping.FieldInfo, valueBytes: ByteBuffer) {
        let (fieldInfo, fieldBytes) = try getFieldInfoAndBytes(forKey: key, atOffset: keyOffset)
        let keyLength = fieldInfo.valueOffset - fieldInfo.keyOffset
        return (fieldInfo, fieldBytes.getSlice(at: keyLength, length: fieldBytes.readableBytes - keyLength)!)
    }
    
    
    func _decode(_ type: Decodable.Type, forKey key: Key, keyOffset: Int?) throws -> Any {
        guard let key = key as? Key else {
            fatalError("Got invalid key")
        }
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
            //} else if T.self is LKProtobufferEmbeddedOneofType.Type {
        } else if (type as? LKProtobufferEmbeddedOneofType.Type) != nil {
            precondition((type as? LKProtobufferEmbeddedOneofType.Type) != nil)
            // We're asked to decode an embedded type (currently only oneof, as far as i'm aware),
            // which means what we need to ignore the coding key.
            // Note: since oneofs can't be repeated (TODO check!) we can ignore a potentially specified offset here
            precondition(keyOffset == nil)
            return try type.init(from: _LKProtobufferDecoder(codingPath: codingPath, buffer: buffer))
        //} else if T.self is LKProtobufferMessage.Type {
        } else if ((type as? LKProtobufferMessage.Type) != nil) || (type == Array<UInt8>.self) || (type == Data.self) {
            // We're asked to decode an embedded message, or a lump of bytes.
            // Embedded messages are essentially the same as normal key-value pairs, but we have to drop the preceding length delimiter first.
            // Same goes for byte fields, the only difference here is that we don't have to decode them into a concrete type.
            let (fieldInfo, valueBytes) = try getFieldInfoAndValueBytes(forKey: key, atOffset: keyOffset)
            precondition(fieldInfo.wireType == .lengthDelimited)
            var adjustedValueBytes = valueBytes
            let length = Int(try adjustedValueBytes.readVarInt())
            precondition(adjustedValueBytes.readableBytes >= length)
            precondition(fieldInfo.valueInfo == .lengthDelimited(dataLength: length, dataOffset: adjustedValueBytes.readerIndex - valueBytes.readerIndex))
            if (type as? LKProtobufferMessage.Type) != nil {
                return try type.init(from: _LKProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: adjustedValueBytes))
            } else if type == Array<UInt8>.self {
                return Array<UInt8>(buffer: adjustedValueBytes)
            } else if type == Data.self {
                return Data(buffer: adjustedValueBytes)
            } else {
                fatalError()
            }
//        } else if (type as? LKProtobufferMessage.Type) != nil {
//            // We're asked to decode an embedded message.
//            // Embedded messages are essentially the same as normal key-value pairs, but we have to drop the preceding length delimiter first
//            let (fieldInfo, valueBytes) = try getFieldInfoAndValueBytes(forKey: key, atOffset: keyOffset)
//            precondition(fieldInfo.wireType == .lengthDelimited)
//            var adjustedValueBytes = valueBytes
//            let length = Int(try adjustedValueBytes.readVarInt())
//            print("AVB", adjustedValueBytes.readableBytes, adjustedValueBytes.lk_getAllBytes())
//            precondition(adjustedValueBytes.readableBytes >= length)
//            precondition(fieldInfo.valueInfo == .lengthDelimited(dataLength: length, dataOffset: adjustedValueBytes.readerIndex - valueBytes.readerIndex))
//            return try type.init(from: _LKProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: adjustedValueBytes))
//        //} else if T.self is __LKProtobufRepeatedValueCodable.Type {
//        } else if (type == Array<UInt8>.self) || (type == Data.self) {
//            let (fieldInfo, valueBytes) = try getFieldInfoAndValueBytes(forKey: key, atOffset: keyOffset)
//            print(self.buffer.lk_getAllBytes().count)
//            var adjustedValueBytes = valueBytes
//            let length = Int(try adjustedValueBytes.readVarInt())
//            precondition(fieldInfo.valueInfo == .lengthDelimited(dataLength: length, dataOffset: adjustedValueBytes.readerIndex - valueBytes.readerIndex))
//            if type == Array<UInt8>.self {
//                return Array<UInt8>(buffer: adjustedValueBytes)
//            } else if type == Data.self {
//                return Data(buffer: adjustedValueBytes)
//            }
//            fatalError()
//        } else if type == Data.self {
            fatalError()
        } else if let repeatedValueCodableTy = type as? __LKProtobufRepeatedValueCodable.Type {
            precondition((type as? __LKProtobufRepeatedValueCodable.Type) != nil)
            let decoder = _LKProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: buffer)
            let retval = try repeatedValueCodableTy.init(
                decodingFrom: decoder,
                forKey: key,
                atFields: fields.getAll(forFieldNumber: key.getProtoFieldNumber())
            )
            return retval
        } else {
            let (fieldInfo, valueBytes) = try getFieldInfoAndValueBytes(forKey: key, atOffset: keyOffset)
            let _A = try type.init(from: _LKProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: valueBytes))
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
