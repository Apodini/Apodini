import NIO
import ApodiniUtils
import Foundation
@_implementationOnly import Runtime


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
        } else if let TI = try? typeInfo(of: Self.self) {
            cachedCodingKeysEnumCases[ObjectIdentifier(Self.self)] = TI.cases
            if let idx = TI.cases.firstIndex(where: { $0.name == self.stringValue }) {
                return idx + 1
            }
        }
        fatalError("Unable to get a proto field number for coding key \(self)")
    }
}


enum ProtoDecodingError: Swift.Error {
    case noData
    case foundDeprecatedWireType(WireType, tag: Int, offset: Int)
    case other(String)
}


enum ProtoEncodingError: Swift.Error {
    case other(String)
}




extension ByteBuffer {
    func canMoveReaderIndex(forwardBy distance: Int) -> Bool {
        return (0...writerIndex).contains(readerIndex + distance)
    }
    
    
    @discardableResult
    mutating func writeProtoKey(forFieldNumber fieldNumber: Int, wireType: WireType) -> Int {
        precondition(fieldNumber > 0, "Invalid field number: \(fieldNumber)")
        return writeProtoVarInt((fieldNumber << 3) | numericCast(wireType.rawValue))
    }
    
    /// Writes a VarInt value to the buffer, **WITHOUT** using the ZigZag encoding!!! (TODO maybe add this at some point in the future?)
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
    
//    @discardableResult
//    mutating func writeProtoVarInt(_ value: UInt64) -> Int {
//
//    }
    
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
        precondition(bytes.count <= 9) // This is the limit, for a maximum of 63 bytess
        
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
//        let varIntLength = writeVarInt(input.readableBytes)
//        let inputLength = buffer.writeImmutableBuffer(input)
//        return varIntLength + inputLength
        writeProtoLengthDelimited(input.readableBytesView)
    }
    
    /// Writes a length-delimited field to the output buffer.
    /// - Returns: the nu,ber of written bytes
    @discardableResult
    mutating func writeProtoLengthDelimited<C: Collection>(_ input: C) -> Int where C.Element == UInt8 {
//        let varIntLength = writeVarInt(input.count)
//        buffer.reserveCapacity(minimumWritableBytes: input.count)
//        let inputLength = buffer.writeBytes(input)
//        return varIntLength + inputLength
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
}





func GetProtoFieldType(_ type: Any.Type) -> FieldDescriptorProto.FieldType {
    if type == Int.self || type == Int64.self { // TODO this will break on a system where Int != Int64
        return .TYPE_INT64
    } else if type == UInt.self || type == UInt64.self {  // TODO this will break on a system where UInt != UInt64
        return .TYPE_UINT64
    } else if type == Int32.self {
        return .TYPE_INT32
    } else if type == UInt32.self {
        return .TYPE_UINT32
    //} else if type == Int16.self || type == UInt16.self // TODO add support for these? and then simply map them to the smallest int where they'd fit. Also add the corresponding logic to the en/decoder!
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
    } else if GetProtoCodingKind(type) == .message {
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
    // TODO give oneofs a dedicated case here?
}

/// Returns whether the type is a message type in protobuf. (Or, rather, would become one.)
func GetProtoCodingKind(_ type: Any.Type) -> ProtoCodingKind? { // TODO is this still needed? we also have GetProtoFieldType and GuessWireType, which kinda go into the same direction
    let conformsToMessageProtocol = (type as? ProtobufMessage.Type) != nil
//    if ((type as? Encodable) == nil) || ((type as? Decodable) == nil) {
//        // A type which conforms neiter to en- nor to decodable
//    }
    
    let isPrimitiveProtoType = (type as? ProtobufPrimitive.Type) != nil
    
    if type == Never.self {
        // We have this as a special case since never isn't really codable, but still allowed as a return type for handlers.
        return .message
    }
    
    if let optionalTy = type as? AnyOptional.Type {
        return GetProtoCodingKind(optionalTy.wrappedType)
    }
    
    guard (type as? Codable.Type) != nil else {
        // A type which isn't codable couldn't be en- or decoded in the first place
        fatalError()
        return nil
    }
    
    if (type as? ProtobufPrimitive.Type) != nil {
        // The type is a primitive
        precondition(!conformsToMessageProtocol)
        return .primitive
    }
    
    guard let TI = try? typeInfo(of: type) else {
        fatalError()
        return nil
    }
    
    switch TI.kind {
    case .struct:
        // The type is a struct, it is codable, but it is not a primitive.
        // What is it?
        // (Jpkes on you i dont know either,,,)
        
        // This is the point where we'd like to just be able to assume that it's a message, but I'm not really comfortable w/ thhat...
        return .message
        fatalError()
    case .enum:
        let isSimpleEnum = (type as? AnyProtobufEnum.Type) != nil
        let isComplexEnum = (type as? AnyProtobufEnumWithAssociatedValues.Type) != nil
        switch (isSimpleEnum, isComplexEnum) { // TODO the protocol names  here in the error messages aren't perfectly correct but we can't use the actual one bc reasons
        case (false, false):
            fatalError("Encountered an enum type (\(String(reflecting: type))) that conforms neither to '\(AnyProtobufEnum.self)' nor to '\(AnyProtobufEnumWithAssociatedValues.self)'")
        case (true, false):
            return .enum
        case (false, true):
            return .enum // TODO use a dedicated case????
        case (true, true):
            fatalError("Invalid enum, type: The '\(AnyProtobufEnum.self)' and '\(AnyProtobufEnumWithAssociatedValues.self)' protocols are mutually exclusive.")
        }
    default:
        // just return nil...!!!
        fatalError()
    }
}
