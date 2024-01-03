//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO
import Foundation
import Apodini
import ApodiniUtils


/// The problem here is that we somehow need to pass a type variable (i.e. a `Decodable.Type` to
/// the `ProtobufferDecoderKeyedDecodingContainer`'s `decode` function.
/// Since `decode`'s signature is `decode<T>(_: T.Type)`, we can't pass the non-generic type as a generic type.
/// We could work around this by simply directly calling the ProtoKeyedEncodingContainer's `_decode(_: Decodable.Type)` function, which is not generic,
/// but that doesn't work, because, due to how Swift implements keyed decoding containers, it is impossible to accesss a `KeyedEncodingContainer`'s
/// internal actual container. (Ideally we'd just do a simple `self as? ProtoKeyedEncodingContainer<Key>` check, but that doesn't work).
/// So we have to work around this by storing the to-be-decoded type in a global variable, and then passing a specific single-purpose type to `decode`,
/// which will not be decoded itself, but rather serves to tell the decode function to decode the type stored in here.
/// (Look, I'm not appy about this either...)
private let typeToDecode = ThreadSpecificVariable<Box<any Decodable.Type>>()


extension KeyedDecodingContainerProtocol {
    @_disfavoredOverload
    func decode(_ type: any Decodable.Type, forKey key: Key) throws -> any Decodable {
        precondition(typeToDecode.currentValue == nil)
        typeToDecode.currentValue = Box(type)
        let helperResult = try decode(DecodeTypeErasedDecodableTypeHelper.self, forKey: key)
        precondition(typeToDecode.currentValue == nil)
        return helperResult.value as! any Decodable
    }
}


private struct DecodeTypeErasedDecodableTypeHelper: Decodable {
    let value: Any
    let originalType: any Decodable.Type
    
    init(value: Any, originalType: any Decodable.Type) {
        self.value = value
        self.originalType = originalType
    }
    
    init(from decoder: any Decoder) throws {
        fatalError("Should be unreachable. If you end up here, that means that you used a decoder which didn't properly handle the \(Self.self) type.")
    }
}


struct ProtobufferDecoderKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let codingPath: [any CodingKey]
    private let buffer: ByteBuffer
    let fields: ProtobufFieldsMapping
    
    var allKeys: [Key] {
        fields.allFields.mapIntoSet(\.tag).compactMap { Key(intValue: $0) }
    }
    
    init(codingPath: [any CodingKey], buffer: ByteBuffer) throws {
        self.codingPath = codingPath
        self.buffer = buffer
        self.fields = try ProtobufMessageLayoutDecoder.getFields(in: buffer)
    }
    
    /// - Note: This will produce unexpected results for some situations, e.g. in cases there the absence of a value indicates the presence of an empty value.
    func contains(_ key: Key) -> Bool {
        fields.contains(fieldNumber: key.getProtoFieldNumber())
    }
    
    func contains(_ key: Key, atOffset offset: Int?) -> Bool {
        if let offset = offset {
            return fields.allFields.contains { $0.tag == key.getProtoFieldNumber() && $0.keyOffset == offset }
        } else {
            return contains(key)
        }
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        // There's differences between proto2 and proto3 which mean that this _might_ be required at some point in the future...
        fatalError("Explicit nil decoding not (yet?) supported")
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
        return try buffer.decodeProtoString(
            fieldValueInfo: fieldInfo.valueInfo,
            fieldValueOffset: fieldInfo.valueOffset,
            codingPath: codingPath,
            makeDataCorruptedError: { errorDesc in
                DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: errorDesc)
            }
        )
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let fieldInfo = fields.getLast(forFieldNumber: key.getProtoFieldNumber()) else {
            return 0
        }
        precondition(fieldInfo.wireType == ._64Bit)
        return try buffer.getProtoDouble(at: fieldInfo.valueOffset)
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard let fieldInfo = fields.getLast(forFieldNumber: key.getProtoFieldNumber()) else {
            return 0
        }
        precondition(fieldInfo.wireType == ._32Bit)
        return try buffer.getProtoFloat(at: fieldInfo.valueOffset)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        try decodeVarInt(forKey: key)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        try throwUnsupportedNumericTypeDecodingError(type, codingPath: codingPath.appending(key))
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        try throwUnsupportedNumericTypeDecodingError(type, codingPath: codingPath.appending(key))
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        try decodeVarInt(forKey: key)
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        try decodeVarInt(forKey: key)
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        try decodeVarInt(forKey: key)
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        try throwUnsupportedNumericTypeDecodingError(type, codingPath: codingPath.appending(key))
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        try throwUnsupportedNumericTypeDecodingError(type, codingPath: codingPath.appending(key))
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        try decodeVarInt(forKey: key)
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        try decodeVarInt(forKey: key)
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
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
        fatalError("Not implemented (key: \(key))")
    }
    
    func superDecoder() throws -> any Decoder {
        fatalError("Not implemented")
    }
    
    func superDecoder(forKey key: Key) throws -> any Decoder {
        fatalError("Not implemented (key: \(key))")
    }
    
    
    // MARK: the type stuff
    
    func getFieldInfoAndBytes(forKey key: Key, atOffset keyOffset: Int?) throws -> (fieldInfo: ProtobufFieldInfo, fieldBytes: ByteBuffer) {
        let fieldNumber = key.getProtoFieldNumber()
        guard fieldNumber > 0 else {
            throw DecodingError.keyNotFound(key, .init(
                codingPath: self.codingPath.appending(key),
                debugDescription: "CodingKey \(key) has an invalid proto field number \(fieldNumber), must be > 0.",
                underlyingError: nil
            ))
        }
        let fieldInfo: ProtobufFieldInfo?
        if let keyOffset = keyOffset {
            fieldInfo = fields.allFields.first { $0.tag == fieldNumber && $0.keyOffset == keyOffset }
        } else {
            fieldInfo = fields.getLast(forFieldNumber: fieldNumber)
        }
        guard let fieldInfo = fieldInfo else {
            throw DecodingError.keyNotFound(key, .init(
                codingPath: self.codingPath.appending(key),
                debugDescription: "Unable to find corresponding proto message field",
                underlyingError: nil
            ))
        }
        return (fieldInfo, buffer.getSlice(at: fieldInfo.keyOffset, length: fieldInfo.fieldLength)!)
    }
    
    
    func getFieldInfoAndValueBytes(
        forKey key: Key,
        atOffset keyOffset: Int?
    ) throws -> (fieldInfo: ProtobufFieldInfo, valueBytes: ByteBuffer) {
        let (fieldInfo, fieldBytes) = try getFieldInfoAndBytes(forKey: key, atOffset: keyOffset)
        let keyLength = fieldInfo.valueOffset - fieldInfo.keyOffset
        return (fieldInfo, fieldBytes.getSlice(at: keyLength, length: fieldBytes.readableBytes - keyLength)!)
    }
    
    
    func _decode( // swiftlint:disable:this identifier_name cyclomatic_complexity
        _ type: any Decodable.Type,
        forKey key: Key,
        keyOffset: Int?
    ) throws -> Any {
        // NOTE the order here is important, since some types might match multiple branches!!!
        if type == DecodeTypeErasedDecodableTypeHelper.self {
            let type = typeToDecode.currentValue!.value
            typeToDecode.currentValue = nil
            return DecodeTypeErasedDecodableTypeHelper(
                value: try _decode(type, forKey: key, keyOffset: keyOffset),
                originalType: type
            )
        } else if (type as? any _ProtobufEmbeddedType.Type) != nil {
            // We're asked to decode an embedded type (currently only oneof, as far as i'm aware),
            // which means what we need to ignore the coding key.
            // Note: since oneofs can't be repeated, we can safely ignore a potentially specified offset here
            precondition(keyOffset == nil)
            return try type.init(from: _ProtobufferDecoder(codingPath: codingPath, buffer: buffer))
        } else if let protobufRepeatedTy = type as? any ProtobufRepeatedDecodable.Type {
            let decoder = _ProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: buffer)
            let retval = try protobufRepeatedTy.init(
                decodingFrom: decoder,
                forKey: key,
                atFields: fields.getAll(forFieldNumber: key.getProtoFieldNumber())
            )
            return retval
        } else if let optionalTy = type as? any AnyOptional.Type {
            return try _decodeIfPresent(optionalTy.wrappedType as! any Decodable.Type, forKey: key, atKeyOffset: keyOffset) as Any
        } else if keyOffset == nil && type == String.self {
            return try decode(String.self, forKey: key)
        } else if keyOffset == nil && type == Int.self {
            return try decode(Int.self, forKey: key)
        } else if keyOffset == nil && type == UInt.self {
            return try decode(UInt.self, forKey: key)
        } else if keyOffset == nil && type == Int64.self {
            return try decode(Int64.self, forKey: key)
        } else if keyOffset == nil && type == UInt64.self {
            return try decode(UInt64.self, forKey: key)
        } else if keyOffset == nil && type == Int32.self {
            return try decode(Int32.self, forKey: key)
        } else if keyOffset == nil && type == UInt32.self {
            return try decode(UInt32.self, forKey: key)
        } else if keyOffset == nil && type == Bool.self {
            return try decode(Bool.self, forKey: key)
        } else if keyOffset == nil && type == Double.self {
            return try decode(Double.self, forKey: key)
        } else if keyOffset == nil && type == Float.self {
            return try decode(Float.self, forKey: key)
        } else {
            if let enumTy = type as? any AnyProtobufEnum.Type, !contains(key, atOffset: keyOffset) {
                // Decoding an enum which is not present in the message, so we need to replace it with the default value
                switch getProtoSyntax(enumTy) {
                case .proto2:
                    // For proto2 enum types, the first value is used as the default (https://developers.google.com/protocol-buffers/docs/proto#enum)
                    return enumTy.allCases.first!
                    // For proto3 enum types, the value which is mapped to 0 is used as the default (https://developers.google.com/protocol-buffers/docs/proto3#enum)
                case .proto3:
                    return enumTy.init(rawValue: 0)!
                }
            }
            let (fieldInfo, valueBytes) = try getFieldInfoAndValueBytes(forKey: key, atOffset: keyOffset)
            switch guessWireType(type)! {
            case .lengthDelimited:
                // We're asked to decode an embedded message, or a lump of bytes.
                // Embedded messages are essentially the same as normal key-value pairs, but we have to drop the preceding length delimiter first.
                // Same goes for byte fields, the only difference here is that we don't have to decode them into a concrete type.
                var adjustedValueBytes = valueBytes
                let length = Int(try adjustedValueBytes.readVarInt())
                precondition(adjustedValueBytes.readableBytes >= length)
                precondition(
                    fieldInfo.valueInfo == .lengthDelimited(dataLength: length, dataOffset: adjustedValueBytes.readerIndex - valueBytes.readerIndex)
                )
                if let bytesMappedTy = type as? any ProtobufBytesMapped.Type {
                    return try bytesMappedTy.init(rawBytes: adjustedValueBytes)
                } else if type == String.self {
                    return try String(from: _ProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: valueBytes))
                } else if type == Foundation.UUID.self {
                    let rawValue = try String(from: _ProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: valueBytes))
                    if let uuid = UUID(uuidString: rawValue) {
                        return uuid
                    } else {
                        throw ProtoDecodingError.unableToParseUUID(rawValue: rawValue)
                    }
                } else if type == Foundation.Date.self {
                    let timestamp = try decode(ProtoTimestamp.self, forKey: key, keyOffset: keyOffset)
                    //return Date(timeIntervalSince1970: TimeInterval(timestamp.seconds) + (TimeInterval(timestamp.nanos) / 1e9))
                    return Date(timeIntervalSince1970: timestamp.timeIntervalSince1970)
                } else if type == Foundation.URL.self {
                    let rawValue = try String(from: _ProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: valueBytes))
                    if let url = URL(string: rawValue) {
                        return url
                    } else {
                        throw ProtoDecodingError.unableToParseURL(rawValue: rawValue)
                    }
                } else {
                    return try type.init(from: _ProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: adjustedValueBytes))
                }
            default:
                return try type.init(from: _ProtobufferDecoder(codingPath: codingPath.appending(key), userInfo: [:], buffer: valueBytes))
            }
        }
    }
    
    
    private func decodeVarInt<T: FixedWidthInteger>(forKey key: Key) throws -> T {
        guard let fieldInfo = fields.getLast(forFieldNumber: key.getProtoFieldNumber()) else {
            return .zero
        }
        return T(truncatingIfNeeded: try buffer.getVarInt(at: fieldInfo.valueOffset))
    }
    
    
    // MARK: Optionals
    
    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? { // swiftlint:disable:this discouraged_optional_boolean
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }

    func decodeIfPresent<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
        implicitForceCast(try _decodeIfPresent(type, forKey: key))
    }
    
    
    private func _decodeIfPresent(_ type: any Decodable.Type, forKey key: Key, atKeyOffset keyOffset: Int? = nil) throws -> Any? {
        if let keyOffset = keyOffset, fields.getAll(forFieldNumber: key.getProtoFieldNumber()).contains(where: { $0.keyOffset == keyOffset }) {
            // We're given an explicit key offset, but can't find something at that offset
            return .none
        } else if fields.getLast(forFieldNumber: key.getProtoFieldNumber()) == nil {
            return .none
        }
        return .some(try _decode(type, forKey: key, keyOffset: keyOffset))
    }
}


func implicitForceCast<T, U>(_ value: T) -> U {
    value as! U
}
