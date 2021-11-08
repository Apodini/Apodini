import NIO
import ApodiniUtils
import Foundation
@_implementationOnly import Runtime


private var cachedCodingKeysEnumCases: [ObjectIdentifier: [Runtime.Case]] = [:]

extension CodingKey {
    func getProtoFieldNumber() -> Int {
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

enum WireType: UInt8, Hashable {
    /// int32, int64, uint32, uint64, sint32, sint64, bool, enum
    case varInt = 0
    /// 64-fixed64, sfixed64, double
    case _64Bit = 1
    /// string, bytes, embedded messages, packed repeated fields
    case lengthDelimited = 2
    /// groups (deprecated)
    @available(*, deprecated)
    case startGroup = 3
    /// groups (deprecated)
    @available(*, deprecated)
    case endGroup = 4
    ///fixed32, sfixed32, float
    case _32Bit = 5
}



/// Attempts to guess the protobuf wire type of the specified type.
/// - Note: This function should only be called with types that can actually be encoded to protobuf, i.e. types that conform to `Encodable`.
func LKGuessWireType(_ type: Any.Type) -> WireType? {
    if type == String.self {
        return .lengthDelimited
    } else if type == Int.self {
        return .varInt
    } else if type == Float.self {
        return ._32Bit
    } else if type == Double.self {
        return ._64Bit
    } else if let TI = try? typeInfo(of: type) {
        // Try to determine the wire type based on the kind of type we're dealing with.
        // For example, all structs that didn't match any of the explicitly-checked-for types above can be assumed to be length-delimited
        switch TI.kind {
        case .struct:
            return .lengthDelimited
        case .enum:
            // TODO do something based on the raw value?
            if (type as? LKProtobufferEmbeddedOneofType.Type) != nil {
                // TODO we have to ignore the key, and the wire type is determined based on the value set!!!
                //return .lengthDelimited
            }
            if (type as? LKAnyProtobufferEnum.Type) != nil {
                return .varInt
            }
            fatalError("Unhandled: \(type)") // TODO how should this be handled?
        case .optional:
            fatalError() // TODO how should this be handled?
        case .opaque:
            fatalError() // TODO how should this be handled? If at all...
        case .tuple:
            fatalError() // TODO how should this be handled? If at all...
        case .function:
            fatalError() // TODO how should this be handled? If at all...
        case .existential:
            fatalError() // TODO how should this be handled? If at all...
        case .metatype:
            fatalError() // TODO how should this be handled? If at all...
        case .objCClassWrapper:
            fatalError() // TODO how should this be handled? If at all...
        case .existentialMetatype:
            fatalError() // TODO how should this be handled? If at all...
        case .foreignClass:
            fatalError() // TODO how should this be handled? If at all...
        case .heapLocalVariable:
            fatalError() // TODO how should this be handled? If at all...
        case .heapGenericLocalVariable:
            fatalError() // TODO how should this be handled? If at all...
        case .errorObject:
            fatalError() // TODO how should this be handled?
        case .class:
            fatalError() // TODO how should this be handled?
        }
    } else {
        fatalError()
    }
}


/// Attempts to guess the protobuf wire type of the specified value.
/// - Note: This function should only be called with values of types that can actually be encoded to protobuf, i.e. types that conform to `Encodable`.
func LKGuessWireType(_ value: Any) -> WireType? { // TODO remove this function!
    return LKGuessWireType(type(of: value))
//    switch value {
//    case is String:
//        precondition(LKGuessWireType(type(of: value)) == .lengthDelimited)
//        return .lengthDelimited
//    case is Int:
//        precondition(LKGuessWireType(type(of: value)) == .varInt)
//        return .varInt
//    case is Float:
//        precondition(LKGuessWireType(type(of: value)) == ._32Bit)
//        return ._32Bit
//    case is Double:
//        precondition(LKGuessWireType(type(of: value)) == ._64Bit)
//        return ._64Bit
//    default:
//        if let TI = try? typeInfo(of: type(of: value)) {
//            // Try to determine the wire type based on the kind of type we're dealing with.
//            // For example, all structs that didn't match any of the explicitly-checked-for types above can be assumed to be length-delimited
//            switch TI.kind {
//            case .struct:
//                precondition(LKGuessWireType(type(of: value)) == .lengthDelimited)
//                return .lengthDelimited
//            case .enum:
//                // TODO do something based on the raw value?
//                if value is LKProtobufferEmbeddedOneofType {
//                    // TODO we have to ignore the key, and the wire type is determined based on the value set!!!
//                    //return .lengthDelimited
//                }
//                fatalError("Unhandled: \(type(of: value))") // TODO how should this be handled?
//            case .optional:
//                fatalError() // TODO how should this be handled?
//            case .opaque:
//                fatalError() // TODO how should this be handled? If at all...
//            case .tuple:
//                fatalError() // TODO how should this be handled? If at all...
//            case .function:
//                fatalError() // TODO how should this be handled? If at all...
//            case .existential:
//                fatalError() // TODO how should this be handled? If at all...
//            case .metatype:
//                fatalError() // TODO how should this be handled? If at all...
//            case .objCClassWrapper:
//                fatalError() // TODO how should this be handled? If at all...
//            case .existentialMetatype:
//                fatalError() // TODO how should this be handled? If at all...
//            case .foreignClass:
//                fatalError() // TODO how should this be handled? If at all...
//            case .heapLocalVariable:
//                fatalError() // TODO how should this be handled? If at all...
//            case .heapGenericLocalVariable:
//                fatalError() // TODO how should this be handled? If at all...
//            case .errorObject:
//                fatalError() // TODO how should this be handled?
//            case .class:
//                fatalError() // TODO how should this be handled?
//            }
//        }
//        return nil
//    }
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



struct LKProtobufFieldsMapping: Hashable {
    struct FieldInfo: Hashable {
        enum ValueInfo: Hashable {
            case varInt(UInt64) // TODO merge the first two cases???
            case _64Bit(UInt64)
            case _32Bit(UInt32)
            /// - parameter length: The size of the field, in bytes
            /// - parameter dataOffset: The offset of the start of the field's data, relative to the start of the length-delimited buffer.
            ///         (I.e.: the number of bytes used by the data-preceding VarInt storing the data's length.)
            case lengthDelimited(dataLength: Int, dataOffset: Int)
            
            /// The `WireType` matching this `ValueInfo`
            var wireType: WireType {
                switch self {
                case .varInt:
                    return .varInt
                case ._64Bit:
                    return ._64Bit
                case ._32Bit:
                    return ._32Bit
                case .lengthDelimited:
                    return .lengthDelimited
                }
            }
        }
        /// The field's number
        let tag: Int
        /// The offset of the field's key, from the beginning of the message.
        let keyOffset: Int
        /// The offset of the field's value, from the beginning of the message.
        /// I.e., this value equals `offset + (size of field key VarInt)`
        let valueOffset: Int
        /// For non-length-delimited fields, the value stored in the field.
        /// If the value's size is smaller than 64 bit, the most significant bits will be empty.
        //let numValue: UInt64
        let valueInfo: ValueInfo // TODO update this after the fact to cache read values?
        /// The length of this field, in bytes.
        let fieldLength: Int
        
        /// The field's wire type
        var wireType: WireType {
            valueInfo.wireType
        }
    }
    
    private var storage: [Int: [FieldInfo]] = [:]
    
    func getAll(forFieldNumber fieldNumber: Int) -> [FieldInfo] {
        storage[fieldNumber] ?? []
    }
    
    func getLast(forFieldNumber fieldNumber: Int) -> FieldInfo? {
        storage[fieldNumber]?.last
    }
    
    mutating func add(_ fieldInfo: FieldInfo) {
        if storage[fieldInfo.tag] == nil {
            storage[fieldInfo.tag] = []
        }
        storage[fieldInfo.tag]!.append(fieldInfo)
    }
    
    func contains(fieldNumber: Int) -> Bool {
        storage.keys.contains(fieldNumber)
    }
    
    var allFields: [FieldInfo] {
        storage.flatMap(\.value)
    }
    
    func debugPrintFieldsInfo() {
        for (fieldTag, fields) in storage.sorted(by: \.key) {
            for field in fields {
                print("[\(fieldTag)] = (keyOffset: \(field.keyOffset), valueOffset: \(field.valueOffset), wireType: \(field.wireType), valueInfo: \(field.valueInfo as Any)")
            }
        }
    }
}



struct ProtobufMessageLayoutDecoder {
    private var buffer: ByteBuffer
//    private var fields: FieldsMapping = [:]
    private var fields = LKProtobufFieldsMapping()
    private var didComputeFields = false
    
    
    private init(buffer: ByteBuffer) {
        //precondition(buffer.readerIndex == 0) // We'll potentially read through the buffer multiple times, which means that we'll be resetting the reader index to 0, so we need to make sure it's 0 in the beginning. TODO just store the initial index as an ivar?
        self.buffer = buffer
    }
    
    static func getFields(in buffer: ByteBuffer) throws -> LKProtobufFieldsMapping {
        var layoutDecoder = Self(buffer: buffer)
        try layoutDecoder.computeFieldInfo()
        return layoutDecoder.fields
    }
    
    
    // (field_number << 3) | wire_type
    
    private mutating func computeFieldInfo() throws {
        guard !didComputeFields else {
            return
        }
        didComputeFields = true
        //buffer.moveReaderIndex(to: 0)
        guard buffer.readableBytes > 0 else {
            throw LKProtoDecodingError.noData
        }
        while buffer.readableBytes > 0 {
            let fieldKeyOffset = buffer.readerIndex
//            guard let fieldKey = try buffer.readVarInt() else {
//                throw Error.other("Unable to read fieldKey VarInt (despite there being data available!)")
//            }
            let fieldKey = try buffer.readVarInt()
            let fieldValueOffset = buffer.readerIndex
            let rawWireType = UInt8(fieldKey & 0b111)
            guard let wireType = WireType(rawValue: rawWireType) else {
                throw LKProtoDecodingError.other("Unable to get wire type (raw value: \(rawWireType))")
            }
            let fieldTag = Int(fieldKey >> 3)
            let fieldValueInfo: LKProtobufFieldsMapping.FieldInfo.ValueInfo
            
            switch wireType {
            case .varInt:
                fieldValueInfo = .varInt(try buffer.readVarInt())
            case ._64Bit:
                guard let u64Val = buffer.readInteger(endianness: .little, as: UInt64.self) else {
                    throw LKProtoDecodingError.other("Unable to read layout")
                }
                fieldValueInfo = ._64Bit(u64Val)
            case ._32Bit:
                guard let u32Val = buffer.readInteger(endianness: .little, as: UInt32.self) else {
                    throw LKProtoDecodingError.other("Unable to read layout")
                }
                fieldValueInfo = ._32Bit(u32Val)
            case .lengthDelimited:
                let varIntValue = try buffer.readVarInt()
                let length = Int(varIntValue)
                fieldValueInfo = .lengthDelimited(
                    dataLength: length,
                    dataOffset: buffer.readerIndex - fieldValueOffset // , buffer.getSlice(at: buffer.readerIndex, length: length)!
                )
                guard buffer.canMoveReaderIndex(forwardBy: Int(length)) else {
                    // We'd be moving the reader beyond the end of the buffer, which:
                    // a) would crash the program because NIO uses a precondition to check this, and (more importantly)
                    // b) indicates to us that the buffer we're reading is not a valid proto message.
                    throw LKProtoDecodingError.noData
                }
                buffer.moveReaderIndex(forwardBy: Int(length))
            case .startGroup, .endGroup:
                throw LKProtoDecodingError.foundDeprecatedWireType(wireType, tag: fieldTag, offset: fieldKeyOffset)
            }
            
            fields.add(LKProtobufFieldsMapping.FieldInfo(
                tag: fieldTag,
                keyOffset: fieldKeyOffset,
                valueOffset: fieldValueOffset,
                valueInfo: fieldValueInfo,
                fieldLength: buffer.readerIndex - fieldKeyOffset
            ))
        }
    }
}




// TODO put this in the same file as the _DataWriter! since its essentially the same code and ops, just the other way around

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
