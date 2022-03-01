//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIO


struct ProtobufFieldInfo: Hashable {
    enum ValueInfo: Hashable {
        case varInt(UInt64)
        case _64Bit(UInt64) // swiftlint:disable:this identifier_name
        case _32Bit(UInt32) // swiftlint:disable:this identifier_name
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
    let valueInfo: ValueInfo
    /// The length of this field, in bytes.
    let fieldLength: Int
    
    /// The field's wire type
    var wireType: WireType {
        valueInfo.wireType
    }
}


struct ProtobufFieldsMapping: Hashable {
    private var storage: [Int: [ProtobufFieldInfo]] = [:]
    
    init() {}
    
    /* for tests only */ internal init(_ mapping: [Int: [ProtobufFieldInfo]]) {
        self.storage = mapping
    }
    
    func getAll(forFieldNumber fieldNumber: Int) -> [ProtobufFieldInfo] {
        storage[fieldNumber] ?? []
    }
    
    func getLast(forFieldNumber fieldNumber: Int) -> ProtobufFieldInfo? {
        storage[fieldNumber]?.last
    }
    
    mutating func add(_ fieldInfo: ProtobufFieldInfo) {
        if storage[fieldInfo.tag] == nil {
            storage[fieldInfo.tag] = []
        }
        storage[fieldInfo.tag]!.append(fieldInfo)
    }
    
    func contains(fieldNumber: Int) -> Bool {
        storage.keys.contains(fieldNumber)
    }
    
    var isEmpty: Bool {
        storage.isEmpty
    }
    
    var allFields: [ProtobufFieldInfo] {
        storage.flatMap(\.value)
    }
    
    var count: Int {
        storage.reduce(into: 0) { $0 += $1.value.count }
    }
    
    func debugPrintFieldsInfo() {
        for (fieldTag, fields) in storage.sorted(by: \.key) {
            for field in fields {
                print("[\(fieldTag)] = (keyOffset: \(field.keyOffset), valueOffset: \(field.valueOffset), wireType: \(field.wireType), valueInfo: \(field.valueInfo as Any)")
            }
        }
    }
}


extension ProtobufFieldsMapping: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (Int, [ProtobufFieldInfo])...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }
}


struct ProtobufMessageLayoutDecoder {
    private var buffer: ByteBuffer
    private var fields = ProtobufFieldsMapping()
    private var didComputeFields = false
    
    private init(buffer: ByteBuffer) {
        self.buffer = buffer
    }
    
    static func getFields(in buffer: ByteBuffer) throws -> ProtobufFieldsMapping {
        var layoutDecoder = Self(buffer: buffer)
        try layoutDecoder.computeFieldInfo()
        return layoutDecoder.fields
    }
    
    
    private mutating func computeFieldInfo() throws {  // swiftlint:disable:this cyclomatic_complexity
        guard !didComputeFields else {
            return
        }
        didComputeFields = true
        guard buffer.readableBytes > 0 else {
            // If there are no readable bytes (i.e. the buffer is empty), we simply return.
            // Empty buffers are perfectly valid (think e.g. a message type containing an empty string and/or empty array)
            return
        }
        while buffer.readableBytes > 0 {
            let fieldKeyOffset = buffer.readerIndex
            let fieldKey = try buffer.readVarInt()
            let fieldValueOffset = buffer.readerIndex
            let rawWireType = UInt8(fieldKey & 0b111)
            guard let wireType = WireType(rawValue: rawWireType) else {
                throw ProtoDecodingError.other("Unable to get wire type (raw value: \(rawWireType))")
            }
            let fieldTag = Int(fieldKey >> 3)
            let fieldValueInfo: ProtobufFieldInfo.ValueInfo
            
            switch wireType {
            case .varInt:
                fieldValueInfo = .varInt(try buffer.readVarInt())
            case ._64Bit:
                guard let u64Val = buffer.readInteger(endianness: .little, as: UInt64.self) else {
                    throw ProtoDecodingError.other("Unable to read layout")
                }
                fieldValueInfo = ._64Bit(u64Val)
            case ._32Bit:
                guard let u32Val = buffer.readInteger(endianness: .little, as: UInt32.self) else {
                    throw ProtoDecodingError.other("Unable to read layout")
                }
                fieldValueInfo = ._32Bit(u32Val)
            case .lengthDelimited:
                let varIntValue = try buffer.readVarInt()
                let length = Int(varIntValue)
                fieldValueInfo = .lengthDelimited(
                    dataLength: length,
                    dataOffset: buffer.readerIndex - fieldValueOffset
                )
                guard buffer.canMoveReaderIndex(forwardBy: Int(length)) else {
                    // We'd be moving the reader beyond the end of the buffer, which:
                    // a) would crash the program because NIO uses a precondition to check this, and (more importantly)
                    // b) indicates to us that the buffer we're reading is not a valid proto message.
                    throw ProtoDecodingError.noData
                }
                buffer.moveReaderIndex(forwardBy: Int(length))
            case .startGroup, .endGroup:
                throw ProtoDecodingError.foundDeprecatedWireType(wireType, tag: fieldTag, offset: fieldKeyOffset)
            }
            
            fields.add(ProtobufFieldInfo(
                tag: fieldTag,
                keyOffset: fieldKeyOffset,
                valueOffset: fieldValueOffset,
                valueInfo: fieldValueInfo,
                fieldLength: buffer.readerIndex - fieldKeyOffset
            ))
        }
    }
}
