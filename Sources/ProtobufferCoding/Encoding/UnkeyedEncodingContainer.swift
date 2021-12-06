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


struct ProtobufferUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    let codingPath: [CodingKey]
    let dstBufferRef: Box<ByteBuffer>
    let context: EncoderContext
    
    private(set) var count: Int = 0
    
    init(codingPath: [CodingKey], dstBufferRef: Box<ByteBuffer>, context: EncoderContext) {
        self.codingPath = codingPath
        self.dstBufferRef = dstBufferRef
        self.context = context
    }
    
    mutating func encodeNil() throws {
        fatalError("Not implemented")
    }
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        fatalError("Not implemented")
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError("Not implemented")
    }
    
    mutating func superEncoder() -> Encoder {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Bool) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: String) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Double) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Float) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Int) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Int8) throws {
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath)
    }
    
    mutating func encode(_ value: Int16) throws {
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath)
    }
    
    mutating func encode(_ value: Int32) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: Int64) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: UInt) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: UInt8) throws {
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath)
    }
    
    mutating func encode(_ value: UInt16) throws {
        try throwUnsupportedNumericTypeEncodingError(value: value, codingPath: codingPath)
    }
    
    mutating func encode(_ value: UInt32) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode(_ value: UInt64) throws {
        fatalError("Not implemented")
    }
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        let encoder = _ProtobufferEncoder(codingPath: codingPath, dstBufferRef: dstBufferRef, context: context)
        try value.encode(to: encoder)
    }
}
