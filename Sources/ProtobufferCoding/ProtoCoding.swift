import NIO
import ApodiniUtils
import Foundation
@_implementationOnly import Runtime


private var cachedCodingKeysEnumCases: [ObjectIdentifier: [Runtime.Case]] = [:]

extension CodingKey {
    func getProtoFieldNumber() -> Int { // TODO we can remove this bc we now require intValue to be nonnil.
        if let intValue = self.intValue {
            return intValue
        } else if let enumCases = cachedCodingKeysEnumCases[ObjectIdentifier(Self.self)] {
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

//func ~= (lhs: Any.Type, rhs: Any.Type) -> Bool {
//    lhs == rhs
//}

//func LKWireTypeForType(_ type: Any.Type) -> WireType? {
//    switch type {
//    case Int.self:
//        return .varInt
//    default:
//        return nil
//    }
//}


func LKShouldSkipEncodingBecauseEmptyValue(_ value: Any) -> Bool {
    switch value {
    case let string as String:
        return string.isEmpty
    default:
        return false
    }
}


enum LKProtoDecodingError: Swift.Error {
    case noData
    case foundDeprecatedWireType(WireType, tag: Int, offset: Int)
    case other(String)
}


enum LKProtoEncodingError: Swift.Error {
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
            throw LKProtoDecodingError.noData
        }
        var bytes: [UInt8] = [
            readInteger(endianness: .little, as: UInt8.self)! // We know there's at least one byte.
        ]
        while (bytes.last! & (1 << 7)) != 0 {
            // we have another byte to parse
            guard let nextByte = readInteger(endianness: .little, as: UInt8.self) else {
                throw LKProtoDecodingError.other(
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
            throw LKProtoDecodingError.noData
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
            throw LKProtoDecodingError.noData
        }
        return Double(bitPattern: bitPattern)
    }
    
    func getProtoDouble(at idx: Int) throws -> Double {
        var copy = self
        copy.moveReaderIndex(to: idx)
        return try copy.readProtoDouble()
    }
}





func LKGetProtoFieldType(_ type: Any.Type) -> FieldDescriptorProto.FieldType {
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
    } else if LKGetProtoCodingKind(type) == .message {
        return .TYPE_MESSAGE
    } else {
        fatalError("Unsupported type '\(type)'")
    }
}
