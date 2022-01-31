//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO
import ApodiniUtils
import Foundation
@_implementationOnly import Runtime


public enum ProtoSyntax: String {
    case proto2
    case proto3
}

private var cachedCodingKeysEnumCases: [ObjectIdentifier: [Runtime.Case]] = [:]

extension CodingKey {
    func getProtoFieldNumber() -> Int {
        if let intValue = self.intValue {
            return intValue
        }
        if let enumCases = cachedCodingKeysEnumCases[ObjectIdentifier(Self.self)] {
            if let idx = enumCases.firstIndex(where: { $0.name == self.stringValue }) {
                return idx + 1
            }
        } else if let typeInfo = try? Runtime.typeInfo(of: Self.self) {
            cachedCodingKeysEnumCases[ObjectIdentifier(Self.self)] = typeInfo.cases
            if let idx = typeInfo.cases.firstIndex(where: { $0.name == self.stringValue }) {
                return idx + 1
            }
        }
        fatalError("Unable to get a proto field number for coding key \(self)")
    }
}


enum ProtoDecodingError: Swift.Error {
    case noData
    case foundDeprecatedWireType(WireType, tag: Int, offset: Int)
    /// The error thrown when the decoder is asked to decode a `Foundation.UUID` value from a field,
    /// but the field's data does not constitute a valid UUID string.
    case unableToParseUUID(rawValue: String)
    /// The error thrown when the decoder is asked to decode a `Foundation.URL` value from a field,
    /// but the field's data does not constitute a valid URL string.
    case unableToParseURL(rawValue: String)
    case other(String)
}


enum ProtoEncodingError: Swift.Error {
    case other(String)
}


/// Checks whether the type is compatible with the protobuf format.
/// This will catch types containing invalid things such as an `Array<T?>` (proto arrays must contain non-optional elements),
/// or enums missing a case mapped to the `0` value.
/// - Throws: If the type is not compatible
/// - Returns: If the type is compatible
func validateTypeIsProtoCompatible(_ type: Any.Type) throws {
    _ = try ProtoSchema(defaultPackageName: "org.apodini.tmp").informAboutType(type)
}


extension ByteBuffer {
    func canMoveReaderIndex(forwardBy distance: Int) -> Bool {
        (0...writerIndex).contains(readerIndex + distance)
    }
    
    @discardableResult
    mutating func writeProtoKey(forFieldNumber fieldNumber: Int, wireType: WireType) -> Int {
        precondition(fieldNumber > 0, "Invalid field number: \(fieldNumber)")
        return writeProtoVarInt((fieldNumber << 3) | numericCast(wireType.rawValue))
    }
    
    /// Writes a VarInt value to the buffer, without using the ZigZag encoding!
    /// - returns: the number of bytes written to the buffer
    @discardableResult
    mutating func writeProtoVarInt<T: FixedWidthInteger>(_ value: T) -> Int {
        var writtenBytes = 0
        var u64Val = UInt64(truncatingIfNeeded: value)
        while u64Val > 127 {
            writeInteger(UInt8(u64Val & 0x7f | 0x80))
            u64Val >>= 7
            writtenBytes += 1
        }
        writeInteger(UInt8(u64Val))
        return writtenBytes + 1
    }
    
    /// Reads the value at the current reader index as a VarInt
    /// - returns: the read number, or `nil` if we were unable to read a number (e.g. because there's no data left to be read)
    mutating func readVarInt() throws -> UInt64 {
        guard readableBytes > 0 else {
            throw ProtoDecodingError.noData
        }
        var bytes: [UInt8] = [
            readInteger(endianness: .little, as: UInt8.self)! // We know there's at least one byte.
        ]
        while (bytes.last! & (1 << 7)) != 0 {
            // we have another byte to parse
            guard let nextByte = readInteger(endianness: .little, as: UInt8.self) else {
                throw ProtoDecodingError.other(
                    "Unexpectedly found no byte to read (even though the VarInt's previous byte indicated that there's be one)"
                )
            }
            bytes.append(nextByte)
        }
        precondition(bytes.count <= 10) // maximum length of a var int is 10 bytes, for negative integers
        
        var result: UInt64 = 0
        for (idx, byte) in bytes.enumerated() { // NOTE that this loop will iterate the VarInt's bytes **least-significant-byte first**!
            result |= UInt64(byte & 0b1111111) << (idx * 7)
        }
        return result
    }
    
    func getVarInt(at idx: Int) throws -> UInt64 {
        var copy = self
        copy.moveReaderIndex(to: idx)
        return try copy.readVarInt()
    }
    
    /// Writes a length-delimited field to the output buffer.
    /// - Note: The arguemt buffer SHOULD NOT be already length-delimited.
    /// - Returns: the number of bytes written to the buffer
    @discardableResult
    mutating func writeProtoLengthDelimited(_ input: ByteBuffer) -> Int {
        writeProtoLengthDelimited(input.readableBytesView)
    }
    
    /// Writes a length-delimited field to the output buffer.
    /// - Returns: the nu,ber of written bytes
    @discardableResult
    mutating func writeProtoLengthDelimited<C: Collection>(_ input: C) -> Int where C.Element == UInt8 {
        let bytesWritten = writeProtoVarInt(input.count) + write(input)
        precondition(bytesWritten > 0)
        return bytesWritten
    }
    
    @discardableResult
    mutating func write<C: Collection>(_ input: C) -> Int where C.Element == UInt8 {
        self.reserveCapacity(minimumWritableBytes: input.count)
        return self.writeBytes(input)
    }
    
    @discardableResult
    mutating func write(_ buffer: ByteBuffer) -> Int {
        write(buffer.readableBytesView)
    }
    
    
    @discardableResult
    mutating func writeProtoFloat(_ value: Float) -> Int {
        precondition(MemoryLayout.size(ofValue: value.bitPattern.littleEndian) == 4)
        return withUnsafeBytes(of: value.bitPattern.littleEndian) {
            write($0)
        }
    }
    
    @discardableResult
    mutating func writeProtoDouble(_ value: Double) -> Int {
        precondition(MemoryLayout.size(ofValue: value.bitPattern.littleEndian) == 8)
        return withUnsafeBytes(of: value.bitPattern.littleEndian) {
            write($0)
        }
    }
    
    
    mutating func readProtoFloat() throws -> Float {
        guard let bitPattern = readInteger(endianness: .little, as: UInt32.self) else {
            throw ProtoDecodingError.noData
        }
        return Float(bitPattern: bitPattern)
    }
    
    func getProtoFloat(at idx: Int) throws -> Float {
        var copy = self
        copy.moveReaderIndex(to: idx)
        return try copy.readProtoFloat()
    }
    
    
    mutating func readProtoDouble() throws -> Double {
        guard let bitPattern = readInteger(endianness: .little, as: UInt64.self) else {
            throw ProtoDecodingError.noData
        }
        return Double(bitPattern: bitPattern)
    }
    
    func getProtoDouble(at idx: Int) throws -> Double {
        var copy = self
        copy.moveReaderIndex(to: idx)
        return try copy.readProtoDouble()
    }
    
    /// Attempts to decode a proto-encoded string
    func decodeProtoString(
        fieldValueInfo: ProtobufFieldInfo.ValueInfo,
        fieldValueOffset: Int,
        codingPath: [CodingKey],
        makeDataCorruptedError: (String) -> Error
    ) throws -> String {
        switch fieldValueInfo {
        case let .lengthDelimited(length, dataOffset):
            guard let bytes = self.getBytes(at: fieldValueOffset + dataOffset, length: length) else {
                // NIO says the `getBytes` function only returns nil if the data is not readable
                throw makeDataCorruptedError("No data")
            }
            if let string = String(bytes: bytes, encoding: .utf8) {
                return string
            } else {
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
}


func getProtoFieldType(_ type: Any.Type) -> FieldDescriptorProto.FieldType {
    if type == Int.self || type == Int64.self {
        return .TYPE_INT64
    } else if type == UInt.self || type == UInt64.self {
        return .TYPE_UINT64
    } else if type == Int32.self {
        return .TYPE_INT32
    } else if type == UInt32.self {
        return .TYPE_UINT32
    } else if type == Bool.self {
        return .TYPE_BOOL
    } else if type == Float.self {
        return .TYPE_FLOAT
    } else if type == Double.self {
        return .TYPE_DOUBLE
    } else if type == String.self {
        return .TYPE_STRING
    } else if type == Array<UInt8>.self || type == Data.self {
        return .TYPE_BYTES
    } else if getProtoCodingKind(type) == .message {
        return .TYPE_MESSAGE
    } else {
        fatalError("Unsupported type '\(type)'")
    }
}


/// what a type becomes when coding it in protobuf
enum ProtoCodingKind {
    case message
    case primitive
    case `enum`
    case oneof
    case repeated
}


func getProtoCodingKind(_ type: Any.Type) -> ProtoCodingKind? { // swiftlint:disable:this cyclomatic_complexity
    let conformsToMessageProtocol = (type as? ProtobufMessage.Type) != nil
    
    if type == Never.self {
        // We have this as a special case since never isn't really codable, but still allowed as a return type for handlers.
        return .message
    }
    
    if let optionalTy = type as? AnyOptional.Type {
        return getProtoCodingKind(optionalTy.wrappedType)
    } else if type as? ProtobufBytesMapped.Type != nil {
        return .primitive
    } else if isProtoRepeatedEncodableOrDecodable(type) {
        return .repeated
    }
    
    guard (type as? Encodable.Type != nil) || (type as? Decodable.Type != nil) else {
        // A type which isn't codable couldn't be en- or decoded in the first place
        fatalError("Type '\(type)' is not supported by ProtobufferCoding, because it does not conform to Codable")
    }
    
    if (type as? ProtobufPrimitive.Type) != nil {
        // The type is a primitive
        precondition(!conformsToMessageProtocol)
        return .primitive
    }
    
    guard let typeInfo = try? Runtime.typeInfo(of: type) else {
        return nil
    }
    
    switch typeInfo.kind {
    case .struct:
        // The type is a struct, it is codable, but it is not a primitive.
        return .message
    case .enum:
        let isSimpleEnum = (type as? AnyProtobufEnum.Type) != nil
        let isComplexEnum = (type as? AnyProtobufEnumWithAssociatedValues.Type) != nil
        switch (isSimpleEnum, isComplexEnum) {
        case (false, false):
            fatalError("Encountered an enum type (\(String(reflecting: type))) that conforms neither to '\(AnyProtobufEnum.self)' nor to '\(AnyProtobufEnumWithAssociatedValues.self)'")
        case (true, false):
            return .enum
        case (false, true):
            return .oneof
        case (true, true):
            fatalError("Invalid enum, type: The '\(AnyProtobufEnum.self)' and '\(AnyProtobufEnumWithAssociatedValues.self)' protocols are mutually exclusive.")
        }
    default:
        return nil
    }
}


/// A Swift wrapper around the `google.protobuf.Timestamp` type
struct ProtoTimestamp: Codable, ProtoTypeInPackage, ProtoTypeWithCustomProtoName {
    static let protoTypename: String = "Timestamp"
    static let package = ProtobufPackageUnit(
        packageName: "google.protobuf",
        filename: "google/protobuf/timestamp.proto"
    )
    
    let seconds: Int64
    let nanos: Int32
    
    init(seconds: Int64, nanos: Int32) {
        self.seconds = seconds
        self.nanos = nanos
    }
    
    init(timeIntervalSince1970 timeInterval: TimeInterval) {
        self.seconds = Int64(timeInterval)
        self.nanos = Int32((timeInterval - floor(timeInterval)) * 1e9)
    }
    
    var timeIntervalSince1970: TimeInterval {
        TimeInterval(seconds) + (TimeInterval(nanos) / 1e9)
    }
}
