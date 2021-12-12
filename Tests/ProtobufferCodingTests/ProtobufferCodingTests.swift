//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable discouraged_optional_boolean nesting

import XCTest
import Foundation
import NIO
@testable import ProtobufferCoding
@testable import ApodiniGRPC


// MARK: Test Utils

private struct _TestFailingError: Swift.Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// A version of `XCTAssertNoThrow` that returns the result of the non-throwing expression
/// - Note: Ideally we'd call this `XCTAssertNoThrow` as well and simply use it as an overload, but that doesn't work bc calls always get resolved to the other definition.
func XCTAssertNoThrowAndReturnResult<T>(
    _ expression: @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> T {
    do {
        return try expression()
    } catch {
        XCTFail("Caught error: \(error). \(message())", file: file, line: line)
        throw _TestFailingError(message: "Unexpectedly threw an error")
    }
}


func XCTAssertEqual(_ buffer: ByteBuffer, _ expectedBytes: [UInt8]) throws {
    let actualBytes = try XCTUnwrap(buffer.getBytes(at: 0, length: buffer.readableBytes))
    XCTAssertEqual(actualBytes, expectedBytes)
}


func assertDecodedMatches<T: Decodable>(_ buffer: ByteBuffer, _ expectedValue: T) throws {
    // If the type is not equatable, we can't check whether the decoded value equals the initial input, so we just ignore this
}


func assertDecodedMatches<T: Decodable & Equatable>(_ buffer: ByteBuffer, _ expectedValue: T) throws {
    let decoded = try ProtobufferDecoder().decode(T.self, from: buffer)
    XCTAssertEqual(decoded, expectedValue)
}


private func ascii(_ char: Character) -> UInt8 {
    char.asciiValue!
}


// rename protoRoundtripTest or smth like that
private func _testImpl<T: Codable & Equatable>(_ input: T, expectedBytes: [UInt8], expectedFieldMapping: ProtobufFieldsMapping) throws {
    let encoded = try ProtobufferEncoder().encode(input)
    try XCTAssertEqual(encoded, expectedBytes)
    switch (expectedFieldMapping.isEmpty, encoded.readableBytes == 0) {
    case (true, true):
        break
    case (false, false):
        XCTAssertEqual(try ProtobufMessageLayoutDecoder.getFields(in: encoded), expectedFieldMapping)
    case (false, true):
        XCTFail("Message empty, despite field mapping being specified")
    case (true, false):
        XCTFail("Message not empty, despite no field mapping being specified")
    }
    if !(expectedBytes.isEmpty && encoded.readableBytes == 0) {
        try assertDecodedMatches(encoded, input)
    }
}


// MARK: Tests


class ProtobufferCodingTests: XCTestCase {
    func testEmptyStruct() throws {
        let input = EmptyMessage()
        let encoded = try ProtobufferEncoder().encode(input)
        try XCTAssertEqual(encoded, [])
        try assertDecodedMatches(encoded, input)
    }
    
    
    func testSimpleStruct_String() throws {
        struct SimpleStructWithStringProperty: Codable, Equatable {
            let value: String
        }
        let input = SimpleStructWithStringProperty(value: "Hello there")
        let encoded = try ProtobufferEncoder().encode(input)
        try XCTAssertEqual(encoded, [0b1010, 11, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101])
        XCTAssertEqual(try ProtobufMessageLayoutDecoder.getFields(in: encoded), ProtobufFieldsMapping([
            1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 11, dataOffset: 1), fieldLength: 13)]
        ]))
        try assertDecodedMatches(encoded, input)
    }
    
    
    func testSimpleStruct_Int() throws {
        struct SimpleStructWithIntProperty: Codable, Equatable {
            let value: Int
        }
//        let input = SimpleStructWithIntProperty(value: 52)
//        let encoded = try ProtobufferEncoder().encode(input)
//        try XCTAssertEqual(encoded, [0b1000, 52])
//        XCTAssertEqual(try ProtobufMessageLayoutDecoder.getFields(in: encoded), ProtobufFieldsMapping([
//            1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(52), fieldLength: 2)]
//        ]))
//        try assertDecodedMatches(encoded, input)
        
        try _testImpl(
            SimpleStructWithIntProperty(value: 52),
            expectedBytes: [0b1000, 52],
            expectedFieldMapping: [
                1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(52), fieldLength: 2)]
            ]
        )
        
        try _testImpl(
            SimpleStructWithIntProperty(value: -12),
            expectedBytes: [0b1000, 244, 255, 255, 255, 255, 255, 255, 255, 255, 1],
            expectedFieldMapping: [
                1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(UInt64(bitPattern: -12)), fieldLength: 11)]
            ]
        )
    }
    
    
    func testSimpleStruct_Float() throws {
        struct SimpleStructWithFloatProperty: Codable, Equatable {
            let value: Float
        }
        
        try _testImpl(
            SimpleStructWithFloatProperty(value: 3.141592654),
            expectedBytes: [0b1101, 219, 15, 73, 64],
            expectedFieldMapping: [
                1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: ._32Bit(1078530011), fieldLength: 5)]
            ]
        )
        try _testImpl(
            SimpleStructWithFloatProperty(value: -2.8),
            expectedBytes: [0b1101, 51, 51, 51, 192],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: ._32Bit(3224580915), fieldLength: 5)]
            ]
        )
        try _testImpl(
            SimpleStructWithFloatProperty(value: -.infinity),
            expectedBytes: [0b1101, 0, 0, 128, 255],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: ._32Bit(4286578688), fieldLength: 5)]
            ]
        )
        try _testImpl(
            SimpleStructWithFloatProperty(value: .infinity),
            expectedBytes: [0b1101, 0, 0, 128, 127],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: ._32Bit(2139095040), fieldLength: 5)]
            ]
        )
    }
    
    
    func testSimpleStruct_Double() throws {
        struct SimpleStructWithDoubleProperty: Codable, Equatable {
            let value: Double
        }
        let input = SimpleStructWithDoubleProperty(value: 3.141592654)
        let encoded = try ProtobufferEncoder().encode(input)
        try XCTAssertEqual(encoded, [0b1001, 80, 69, 82, 84, 251, 33, 9, 64])
        XCTAssertEqual(try ProtobufMessageLayoutDecoder.getFields(in: encoded), ProtobufFieldsMapping([
            1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: ._64Bit(4614256656552969552), fieldLength: 9)]
        ]))
        try assertDecodedMatches(encoded, input)
        
        
        try _testImpl(
            SimpleStructWithDoubleProperty(value: 3.141592654),
            expectedBytes: [0b1001, 80, 69, 82, 84, 251, 33, 9, 64],
            expectedFieldMapping: [
                1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: ._64Bit(4614256656552969552), fieldLength: 9)]
            ]
        )
        try _testImpl(
            SimpleStructWithDoubleProperty(value: -2.8),
            expectedBytes: [0b1001, 102, 102, 102, 102, 102, 102, 6, 192],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: ._64Bit(13836859495133111910), fieldLength: 9)]
            ]
        )
        try _testImpl(
            SimpleStructWithDoubleProperty(value: -.infinity),
            expectedBytes: [0b1001, 0, 0, 0, 0, 0, 0, 240, 255],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: ._64Bit(18442240474082181120), fieldLength: 9)]
            ]
        )
        try _testImpl(
            SimpleStructWithDoubleProperty(value: .infinity),
            expectedBytes: [0b1001, 0, 0, 0, 0, 0, 0, 240, 127],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: ._64Bit(9218868437227405312), fieldLength: 9)]
            ]
        )
    }
    
    
    func testSimpleStructWithCustomFieldNumber() throws {
        struct SimpleStructWithStringProperty: Codable, Equatable {
            let value: String
            enum CodingKeys: Int, CodingKey {
                case value = 12
            }
        }
        let input = SimpleStructWithStringProperty(value: "Hello there")
        let encoded = try ProtobufferEncoder().encode(input)
        try XCTAssertEqual(encoded, [98, 11, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101])
        XCTAssertEqual(try ProtobufMessageLayoutDecoder.getFields(in: encoded), ProtobufFieldsMapping([
            12: [
                ProtobufFieldInfo(
                    tag: 12,
                    keyOffset: 0,
                    valueOffset: 1,
                    valueInfo: .lengthDelimited(dataLength: 11, dataOffset: 1),
                    fieldLength: 13
                )
            ]
        ]))
        try assertDecodedMatches(encoded, input)
    }
    
    
    func testGenericStruct() throws {
        try _testImpl(
            GenericSingleFieldMessage<String>(value: "Hello there"),
            expectedBytes: [0b1010, 11, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101],
            expectedFieldMapping: [
                1: [
                    ProtobufFieldInfo(
                        tag: 1,
                        keyOffset: 0,
                        valueOffset: 1,
                        valueInfo: .lengthDelimited(dataLength: 11, dataOffset: 1),
                        fieldLength: 13
                    )
                ]
            ]
        )
        
        try _testImpl(
            GenericSingleFieldMessage<Int>(value: 12),
            expectedBytes: [0b1000, 12],
            expectedFieldMapping: [
                1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(12), fieldLength: 2)]
            ]
        )
    }
    
    
    func testOptional() throws {
        try _testImpl(
            GenericSingleFieldMessage<Int?>(value: 12),
            expectedBytes: [0b1000, 12],
            expectedFieldMapping: [
                1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(12), fieldLength: 2)]
            ]
        )
        try _testImpl(
            GenericSingleFieldMessage<Int?>(value: -12),
            expectedBytes: [0b1000, 244, 255, 255, 255, 255, 255, 255, 255, 255, 1],
            expectedFieldMapping: [
                1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(UInt64(bitPattern: -12)), fieldLength: 11)]
            ]
        )
        try _testImpl(
            GenericSingleFieldMessage<Int?>(value: 0),
            expectedBytes: [0b1000, 0],
            expectedFieldMapping: [
                1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(0), fieldLength: 2)]
            ]
        )
        try _testImpl(
            GenericSingleFieldMessage<Int?>(value: .none),
            expectedBytes: [],
            expectedFieldMapping: [:]
        )
    }
    
    
    func testProto2Compatibility() throws {
        struct Proto3Type<T: Codable & Equatable>: Codable, Equatable {
            let value: T
        }
        struct Proto2Type<T: Codable & Equatable>: Codable, Equatable, Proto2Codable {
            let value: T
        }
        try _testImpl(
            Proto3Type<String>(value: ""),
            expectedBytes: [],
            expectedFieldMapping: [:]
        )
        try _testImpl(
            Proto2Type<String>(value: ""),
            expectedBytes: [0b1010, 0],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 0, dataOffset: 1), fieldLength: 2)]
            ]
        )
    }
    
    
    func testSkipsEmptyValues() throws {
        func imp<T: Codable & Equatable>(_: T.Type, emptyValue: T) throws {
            try _testImpl(GenericSingleFieldMessage<T>(value: emptyValue), expectedBytes: [], expectedFieldMapping: [:])
            try _testImpl(GenericSingleFieldMessage<[T]>(value: []), expectedBytes: [], expectedFieldMapping: [:])
        }
        
        try imp(String.self, emptyValue: "")
        try imp(Bool.self, emptyValue: false)
        try imp(Int.self, emptyValue: 0)
        try imp(Int32.self, emptyValue: 0)
        try imp(Int64.self, emptyValue: 0)
        try imp(Float.self, emptyValue: 0)
        try imp(Float.self, emptyValue: -0)
        try imp(Double.self, emptyValue: 0)
        try imp(Double.self, emptyValue: -0)
    }
    
    
    func testRepeatedValueCoding() throws {
        try _testImpl(
            GenericSingleFieldMessage<[Int]>(value: [1, 2, 3]),
            expectedBytes: [0b1010, 3, 1, 2, 3],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 3, dataOffset: 1), fieldLength: 5)]
            ]
        )
        try _testImpl(
            GenericSingleFieldMessage<[Int]>(value: [0, 1, 2, 3, 4, 5]),
            expectedBytes: [10, 6, 0, 1, 2, 3, 4, 5],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 6, dataOffset: 1), fieldLength: 8)]
            ]
        )
        
        try _testImpl(
            GenericSingleFieldMessage<[String]>(value: ["Lukas", "Kollmer"]),
            expectedBytes: [
                0b1010, 5, ascii("L"), ascii("u"), ascii("k"), ascii("a"), ascii("s"),
                0b1010, 7, ascii("K"), ascii("o"), ascii("l"), ascii("l"), ascii("m"), ascii("e"), ascii("r")
            ],
            expectedFieldMapping: [
                1: [
                    .init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 5, dataOffset: 1), fieldLength: 7),
                    .init(tag: 1, keyOffset: 7, valueOffset: 8, valueInfo: .lengthDelimited(dataLength: 7, dataOffset: 1), fieldLength: 9)
                ]
            ]
        )
    }
    
    
    func testRepeatedValueCodingOrderIrrelevance() throws {
        struct Message: Codable, Equatable {
            let names: [String]
            let number: Int
        }
        
        let bytes: [UInt8] = [
            0b1010, 5, ascii("L"), ascii("u"), ascii("k"), ascii("a"), ascii("s"),
            0b10000, 52,
            0b1010, 4, ascii("P"), ascii("a"), ascii("u"), ascii("l")
        ]
        
        let decoded = try ProtobufferDecoder().decode(Message.self, from: Data(bytes))
        XCTAssertEqual(decoded, Message(names: ["Lukas", "Paul"], number: 52))
    }
    
    
    func testSimpleEnumCoding() throws {
        enum Shape: Int32, ProtobufEnum {
            case square = 0
            case circle = 1
            case triangle = 2
        }
        
        try _testImpl(
            GenericSingleFieldMessage<Shape>(value: .square),
            expectedBytes: [],
            expectedFieldMapping: [:]
        )
        try _testImpl(
            GenericSingleFieldMessage<Shape>(value: .circle),
            expectedBytes: [0b1000, 1],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(1), fieldLength: 2)]
            ]
        )
        try _testImpl(
            GenericSingleFieldMessage<Shape>(value: .triangle),
            expectedBytes: [0b1000, 2],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(2), fieldLength: 2)]
            ]
        )
    }
    
    
    func testProtoSchemaSimpleEnumHandling() throws {
        // First, we make sure that the schema (which acts as the central "type validation" facility)
        // properly handles a simple (i.e. trivial, i.e. non-complex) enum.
        enum Shape: Int32, ProtobufEnum {
            case square = 0
            case circle = 1
            case triangle = 2
        }
        let schema = ProtoSchema(defaultPackageName: "de.lukaskollmer")
        let protoType1 = try XCTAssertNoThrowAndReturnResult(try schema.informAboutType(Shape.self))
        XCTAssertEqual(protoType1, .enumTy(name: .init(mangled: "[de.lukaskollmer].ProtobufferCodingTests.Shape"), enumType: Shape.self, cases: [
            .init(name: "square", value: 0),
            .init(name: "circle", value: 1),
            .init(name: "triangle", value: 2)
        ]))
    }
    
    
    func testProtoSchemaEnumZeroValueHandlingProto2() throws {
        // in proto2, enums w/out a 0 value are allowed, so we expect the enum defined below to work just fine
        enum Proto2ValidShape: Int32, ProtobufEnum, Proto2Codable {
            case square = 1
            case circle = 2
            case triangle = 3
        }
        
        let schema = ProtoSchema(defaultPackageName: "de.lukaskollmer")
        let protoType = try XCTAssertNoThrowAndReturnResult(schema.informAboutType(Proto2ValidShape.self))
        XCTAssertEqual(protoType, .enumTy(
            name: .init(mangled: "[de.lukaskollmer].ProtobufferCodingTests.Proto2ValidShape"),
            enumType: Proto2ValidShape.self,
            cases: [
                .init(name: "square", value: 1),
                .init(name: "circle", value: 2),
                .init(name: "triangle", value: 3)
            ]
        ))
    }
    
    
    func testProtoSchemaEnumZeroValueHandlingProto3() throws {
        // in proto3, enums are required to map the 0 value, so we expedt the enum defined below to result in an error
        enum Proto3InvalidShape: Int32, ProtobufEnum {
            case square = 1
            case circle = 2
            case triangle = 3
        }
        
        let schema = ProtoSchema(defaultPackageName: "de.lukaskollmer")
        XCTAssertThrowsError(try schema.informAboutType(Proto3InvalidShape.self))
    }
    
    
    func testEnumWithAssociatedValues() throws {
        struct Message: Codable, Equatable {
            enum Value: ProtobufEnumWithAssociatedValues, Codable, Equatable {
                case integer(Int)
                case float(Float)
                case double(Double)
                case string(String)
                
                enum CodingKeys: Int, ProtobufMessageCodingKeys {
                    case integer = 1
                    case float = 2
                    case double = 3
                    case string = 4
                }
                
                static func makeEnumCase(forCodingKey codingKey: CodingKeys, payload: Any?) -> Value {
                    switch codingKey {
                    case .integer:
                        return .integer(payload as! Int)
                    case .float:
                        return .float(payload as! Float)
                    case .double:
                        return .double(payload as! Double)
                    case .string:
                        return .string(payload as! String)
                    }
                }
            }
            
            let value: Value
        }
        
        // We have to check multiple things here:
        // 1. It always encodes only one field (and the correct one!)
        // 2. It also encodes zero values (since otherwise there's no way to know which of the oneof's fields was set)
        
        // Test Int
        try _testImpl(
            Message(value: .integer(52)),
            expectedBytes: [0b1000, 52],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(52), fieldLength: 2)]
            ]
        )
        try _testImpl(
            Message(value: .integer(0)),
            expectedBytes: [0b1000, 0],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(0), fieldLength: 2)]
            ]
        )
        
        // Test Float
        try _testImpl(
            Message(value: .float(1.2)),
            expectedBytes: [0b10101, 154, 153, 153, 63],
            expectedFieldMapping: [
                2: [.init(tag: 2, keyOffset: 0, valueOffset: 1, valueInfo: ._32Bit(1067030938), fieldLength: 5)]
            ]
        )
        try _testImpl(
            Message(value: .float(0)),
            expectedBytes: [0b10101, 0, 0, 0, 0],
            expectedFieldMapping: [
                2: [.init(tag: 2, keyOffset: 0, valueOffset: 1, valueInfo: ._32Bit(0), fieldLength: 5)]
            ]
        )
        
        // Test Double
        try _testImpl(
            Message(value: .double(1.2)),
            expectedBytes: [0b11001, 51, 51, 51, 51, 51, 51, 243, 63],
            expectedFieldMapping: [
                3: [.init(tag: 3, keyOffset: 0, valueOffset: 1, valueInfo: ._64Bit(4608083138725491507), fieldLength: 9)]
            ]
        )
        try _testImpl(
            Message(value: .double(0)),
            expectedBytes: [0b11001, 0, 0, 0, 0, 0, 0, 0, 0],
            expectedFieldMapping: [
                3: [.init(tag: 3, keyOffset: 0, valueOffset: 1, valueInfo: ._64Bit(0), fieldLength: 9)]
            ]
        )
        try _testImpl(
            Message(value: .double(-Double.zero)),
            expectedBytes: [0b11001, 0, 0, 0, 0, 0, 0, 0, 128],
            expectedFieldMapping: [
                3: [.init(tag: 3, keyOffset: 0, valueOffset: 1, valueInfo: ._64Bit(9223372036854775808), fieldLength: 9)]
            ]
        )
        XCTAssertEqual(128 << (7 * 8), (-Double.zero).bitPattern)
        XCTAssertEqual((128 << (7 * 8)) as UInt64, 9223372036854775808)
        
        // Test String
        try _testImpl(
            Message(value: .string("Hello")),
            expectedBytes: [0b100010, 5, 72, 101, 108, 108, 111],
            expectedFieldMapping: [
                4: [.init(tag: 4, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 5, dataOffset: 1), fieldLength: 7)]
            ]
        )
        try _testImpl(
            Message(value: .string("")),
            expectedBytes: [0b100010, 0],
            expectedFieldMapping: [
                4: [.init(tag: 4, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 0, dataOffset: 1), fieldLength: 2)]
            ]
        )
    }
    
    
    func testDecodeGRPCReflectionInput1() throws {
        try _testImpl(
            ReflectionRequest(host: "", messageRequest: .listServices("*")),
            expectedBytes: [58, 1, 42],
            expectedFieldMapping: [
                7: [.init(tag: 7, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 1, dataOffset: 1), fieldLength: 3)]
            ]
        )
    }
    
    
    func testDecodeGRPCReflectionInput2() throws {
        try _testImpl(
            ReflectionRequest(host: "", messageRequest: .fileContainingSymbol("de.lukaskollmer.TestWebService")),
            expectedBytes: [
                34, 30, 100, 101, 46, 108, 117, 107, 97, 115, 107,
                111, 108, 108, 109, 101, 114, 46, 84, 101, 115, 116,
                87, 101, 98, 83, 101, 114, 118, 105, 99, 101
            ],
            expectedFieldMapping: [
                4: [.init(tag: 4, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 30, dataOffset: 1), fieldLength: 32)]
            ]
        )
    }
    
    
    func testDecodeGRPCReflectionInput3() throws {
        try _testImpl(
            ReflectionRequest(host: "", messageRequest: .fileContainingSymbol("grpc.reflection.v1alpha.ServerReflection")),
            expectedBytes: [
                34, 40, 103, 114, 112, 99, 46, 114, 101, 102, 108,
                101, 99, 116, 105, 111, 110, 46, 118, 49, 97, 108,
                112, 104, 97, 46, 83, 101, 114, 118, 101, 114, 82,
                101, 102, 108, 101, 99, 116, 105, 111, 110
            ],
            expectedFieldMapping: [
                4: [.init(tag: 4, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 40, dataOffset: 1), fieldLength: 42)]
            ]
        )
    }
    
    
    func testDecodeGRPCReflectionInput4() throws {
        try _testImpl(
            ReflectionRequest(host: "", messageRequest: .fileByFilename("google/protobuf/descriptor.proto")),
            expectedBytes: [
                26, 32, 103, 111, 111, 103, 108, 101, 47, 112, 114,
                111, 116, 111, 98, 117, 102, 47, 100, 101, 115, 99,
                114, 105, 112, 116, 111, 114, 46, 112, 114, 111, 116, 111
            ],
            expectedFieldMapping: [
                3: [.init(tag: 3, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 32, dataOffset: 1), fieldLength: 34)]
            ]
        )
    }
    
    
    func testDecodePositiveInt() throws {
        let positiveData = Data([8, 185, 96])
        let positiveExpected: Int = 12345
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<Int>.self, from: positiveData)
        XCTAssertEqual(message.value, positiveExpected)
    }
    
    func testDecodeNegativeInt() throws {
        let negativeData = Data([8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1])
        let negativeExpected: Int = -12345
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<Int>.self, from: negativeData)
        XCTAssertEqual(message.value, negativeExpected)
    }
    
    func testDecodePositiveInt32() throws {
        let positiveData = Data([8, 185, 96])
        let positiveExpected: Int32 = 12345
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<Int32>.self, from: positiveData)
        XCTAssertEqual(message.value, positiveExpected)
    }
    
    func testDecodeNegativeInt32() throws {
        let negativeData = Data([8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1])
        let negativeExpected: Int32 = -12345
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<Int32>.self, from: negativeData)
        XCTAssertEqual(message.value, negativeExpected)
    }
    
    func testDecodeInt64() throws {
        let positiveData = Data([8, 185, 96])
        let positiveExpected: Int64 = 12345
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<Int64>.self, from: positiveData)
        XCTAssertEqual(message.value, positiveExpected)
    }
    
    func testDecodeOptionalNegativeInt32() throws {
        let negativeData = Data([8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1])
        let negativeExpected: Int32? = -12345
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<Int32?>.self, from: negativeData)
        XCTAssertEqual(message.value, negativeExpected)
    }
    
    func testDecodeUInt() throws {
        let data = Data([8, 185, 96])
        let expected: UInt = 12345
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<UInt>.self, from: data)
        XCTAssertEqual(message.value, expected)
    }
    
    func testDecodeUInt32() throws {
        let data = Data([8, 185, 96])
        let expected: UInt32 = 12345
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<UInt32>.self, from: data)
        XCTAssertEqual(message.value, expected)
    }
    
    func testDecodeUInt64() throws {
        let data = Data([8, 185, 96])
        let expected: UInt64 = 12345
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<UInt64>.self, from: data)
        XCTAssertEqual(message.value, expected)
    }
    
    func testDecodeBool() throws {
        let data = Data([8, 1])
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<Bool>.self, from: data)
        XCTAssertEqual(message.value, true)
    }
    
    func testDecodeDouble() throws {
        let data = Data([9, 88, 168, 53, 205, 143, 28, 200, 64])
        let expected: Double = 12345.12345
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<Double>.self, from: data)
        XCTAssertEqual(message.value, expected)
    }
    
    func testDecodeFloat() throws {
        let data = Data([13, 126, 228, 64, 70])
        let expected: Float = 12345.12345
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<Float>.self, from: data)
        XCTAssertEqual(message.value, expected)
    }
    
    func testDecodeString() throws {
        let data = Data([10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
        let expected: String = "Hello World"
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<String>.self, from: data)
        XCTAssertEqual(message.value, expected)
    }
    
    func testDecodeOptionalString() throws {
        let data = Data([10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
        let expected: String? = "Hello World"
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<String?>.self, from: data)
        XCTAssertEqual(message.value, expected)
    }
    
    func testDecodeBytes() throws {
        let data = Data([10, 6, 1, 2, 3, 253, 254, 255])
        let expected = Data([1, 2, 3, 253, 254, 255])
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<Data>.self, from: data)
        XCTAssertEqual(message.value, expected)
    }
    
    func testDecodeRepeatedBool() throws {
        try _testImpl(
            SingleFieldProtoTestMessage<[Bool]>(value: [true, false, true]),
            expectedBytes: [0b1010, 3, 1, 0, 1],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 3, dataOffset: 1), fieldLength: 5)]
            ]
        )
    }
    
    func testDecodeRepeatedInt() throws {
        try _testImpl(
            SingleFieldProtoTestMessage<[Int]>(value: [0, 1, 2, 3, 4, 5]),
            expectedBytes: [0b1010, 6, 0, 1, 2, 3, 4, 5],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 6, dataOffset: 1), fieldLength: 8)]
            ]
        )
    }
    
    func testDecodeRepeatedInt32() throws {
        try _testImpl(
            SingleFieldProtoTestMessage<[Int32]>(value: [0, 1, 2, 3, 4, 5]),
            expectedBytes: [0b1010, 6, 0, 1, 2, 3, 4, 5],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 6, dataOffset: 1), fieldLength: 8)]
            ]
        )
    }
    
    func testDecodeRepeatedInt64() throws {
        try _testImpl(
            SingleFieldProtoTestMessage<[Int64]>(value: [1234567891011, 1234567891012, 1234567891013, 1234567891014, 1234567891015]),
            expectedBytes: [
                0b1010, 30, 195, 144, 236, 143, 247, 35,
                196, 144, 236, 143, 247, 35, 197, 144,
                236, 143, 247, 35, 198, 144, 236, 143,
                247, 35, 199, 144, 236, 143, 247, 35
            ],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 30, dataOffset: 1), fieldLength: 32)]
            ]
        )
    }
    
    func testDecodeRepeatedFloat() throws {
        try _testImpl(
            SingleFieldProtoTestMessage<[Float]>(value: [123.123, 123.234, 123.345, 123.456, 123.567]),
            expectedBytes: [
                0b1010, 20, 250, 62, 246, 66, 207, 119,
                246, 66, 164, 176, 246, 66, 121, 233,
                246, 66, 78, 34, 247, 66
            ],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 20, dataOffset: 1), fieldLength: 22)]
            ]
        )
    }
    
    func testDecodeRepeatedDouble() throws {
        try _testImpl(
            SingleFieldProtoTestMessage<[Double]>(value: [123456789.123456789, 123456789.223456789, 123456789.323456789]),
            expectedBytes: [
                0b1010, 24, 117, 107, 126, 84, 52, 111,
                157, 65, 219, 209, 228, 84, 52, 111,
                157, 65, 66, 56, 75, 85, 52, 111,
                157, 65
            ],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 24, dataOffset: 1), fieldLength: 26)]
            ]
        )
    }
    
    func testDecodeRepeatedUInt() throws {
        try _testImpl(
            SingleFieldProtoTestMessage<[UInt]>(value: [0, 1, 2, 3, 4, 5]),
            expectedBytes: [0b1010, 6, 0, 1, 2, 3, 4, 5],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 6, dataOffset: 1), fieldLength: 8)]
            ]
        )
    }
    
    func testDecodeRepeatedUInt32() throws {
        //let message = try ProtobufferDecoder().decode(ProtoTestMessage<[UInt32]>.self, from: data)
        //XCTAssertEqual(message.content, expected)
        try _testImpl(
            SingleFieldProtoTestMessage<[UInt32]>(value: [0, 1, 2, 3, 4, 5]),
            expectedBytes: [0b1010, 6, 0, 1, 2, 3, 4, 5],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 6, dataOffset: 1), fieldLength: 8)]
            ]
        )
    }
    
    func testDecodeRepeatedUInt64() throws {
        try _testImpl(
            SingleFieldProtoTestMessage<[UInt64]>(value: [0, 1, 2, 3, 4, 5]),
            expectedBytes: [0b1010, 6, 0, 1, 2, 3, 4, 5],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 6, dataOffset: 1), fieldLength: 8)]
            ]
        )
    }
    
    func testDecodeRepeatedData() throws {
        let data = Data([10, 2, 1, 2, 10, 2, 3, 4, 10, 2, 5, 6])
        let bytes1: [UInt8] = [1, 2]
        let bytes2: [UInt8] = [3, 4]
        let bytes3: [UInt8] = [5, 6]
        let expected: [Data] = [Data(bytes1), Data(bytes2), Data(bytes3)]
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<[Data]>.self, from: data)
        XCTAssertEqual(message.value, expected)
        
        try _testImpl(
            SingleFieldProtoTestMessage<[Data]>(value: [Data([1, 2]), Data([3, 4]), Data([5, 6])]),
            expectedBytes: [0b1010, 2, 1, 2, 10, 2, 3, 4, 10, 2, 5, 6],
            expectedFieldMapping: [
                1: [
                    .init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 2, dataOffset: 1), fieldLength: 4),
                    .init(tag: 1, keyOffset: 4, valueOffset: 5, valueInfo: .lengthDelimited(dataLength: 2, dataOffset: 1), fieldLength: 4),
                    .init(tag: 1, keyOffset: 8, valueOffset: 9, valueInfo: .lengthDelimited(dataLength: 2, dataOffset: 1), fieldLength: 4)
                ]
            ]
        )
    }
    
    func testDecodeRepeatedString() throws {
        let data = Data([10, 4, 101, 105, 110, 115, 10, 4, 122, 119, 101, 105, 10, 4, 100, 114, 101, 105])
        let expected = ["eins", "zwei", "drei"]
        let message = try ProtobufferDecoder().decode(SingleFieldProtoTestMessage<[String]>.self, from: data)
        XCTAssertEqual(message.value, expected)
        
        try _testImpl(
            SingleFieldProtoTestMessage<[String]>(value: ["eins", "zwei", "drei"]),
            expectedBytes: [0b1010, 4, 101, 105, 110, 115, 10, 4, 122, 119, 101, 105, 10, 4, 100, 114, 101, 105],
            expectedFieldMapping: [
                1: [
                    .init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 4, dataOffset: 1), fieldLength: 6),
                    .init(tag: 1, keyOffset: 6, valueOffset: 7, valueInfo: .lengthDelimited(dataLength: 4, dataOffset: 1), fieldLength: 6),
                    .init(tag: 1, keyOffset: 12, valueOffset: 13, valueInfo: .lengthDelimited(dataLength: 4, dataOffset: 1), fieldLength: 6)
                ]
            ]
        )
    }
    
    // MARK: Complex message
    
    let expectedComplexMessage = ProtoComplexTestMessage(
        numberInt32: -12345,
        numberUint32: 12345,
        numberBool: true,
        enumValue: 2,
        numberDouble: 12345.12345,
        content: "Hello World",
        byteData: Data([1, 2, 3, 253, 254, 255]),
        nestedMessage: SingleFieldProtoTestMessage(
            value: "Hallo, das ist eine Sub-Nachricht."
        ),
        numberFloat: 12345.12345
    )
    
    func testDecodeComplexMessage() throws {
        let dataComplexMessage = Data([
            8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1,
            16, 185, 96, 32, 1, 40, 2, 65, 88, 168, 53, 205,
            143, 28, 200, 64, 74, 11, 72, 101, 108, 108, 111,
            32, 87, 111, 114, 108, 100, 82, 6, 1, 2, 3, 253, 254,
            255, 90, 36, 10, 34, 72, 97, 108, 108, 111, 44, 32,
            100, 97, 115, 32, 105, 115, 116, 32, 101, 105, 110,
            101, 32, 83, 117, 98, 45, 78, 97, 99, 104, 114, 105,
            99, 104, 116, 46, 117, 126, 228, 64, 70
        ])
        let message = try ProtobufferDecoder().decode(ProtoComplexTestMessage.self, from: dataComplexMessage)
        XCTAssertEqual(message.numberInt32, expectedComplexMessage.numberInt32)
        XCTAssertEqual(message.numberUint32, expectedComplexMessage.numberUint32)
        XCTAssertEqual(message.numberBool, expectedComplexMessage.numberBool)
        XCTAssertEqual(message.enumValue, expectedComplexMessage.enumValue)
        XCTAssertEqual(message.numberDouble, expectedComplexMessage.numberDouble)
        XCTAssertEqual(message.content, expectedComplexMessage.content)
        XCTAssertEqual(message.byteData, expectedComplexMessage.byteData)
        XCTAssertEqual(message.nestedMessage.value, expectedComplexMessage.nestedMessage.value)
        XCTAssertEqual(message.numberFloat, expectedComplexMessage.numberFloat)
    }
    
    
    // MARK: Complex Coding Tests
    
    let expectedComplexMessageBytes: [UInt8] = [
        8, 199, 159, 255, 255, 255, 255, 255, 255, 255,
        1, 16, 185, 96, 32, 1, 40, 2, 65, 88, 168, 53,
        205, 143, 28, 200, 64, 74, 11, 72, 101, 108, 108,
        111, 32, 87, 111, 114, 108, 100, 82, 6, 1, 2, 3,
        253, 254, 255, 90, 36, 10, 34, 72, 97, 108, 108, 111,
        44, 32, 100, 97, 115, 32, 105, 115, 116, 32, 101,
        105, 110, 101, 32, 83, 117, 98, 45, 78, 97, 99, 104,
        114, 105, 99, 104, 116, 46, 117, 126, 228, 64, 70
    ]
    
    let complexMessage = ProtoComplexTestMessage(
        numberInt32: -12345,
        numberUint32: 12345,
        numberBool: true,
        enumValue: 2,
        numberDouble: 12345.12345,
        content: "Hello World",
        byteData: Data([1, 2, 3, 253, 254, 255]),
        nestedMessage: SingleFieldProtoTestMessage(
            value: "Hallo, das ist eine Sub-Nachricht."
        ),
        numberFloat: 12345.12345
    )
    
    let complexMessageWithOptionalsAllSet = ProtoComplexTestMessageWithOptionals(
        numberInt32: -12345,
        numberUint32: 12345,
        numberBool: true,
        enumValue: 2,
        numberDouble: 12345.12345,
        content: "Hello World",
        byteData: Data([1, 2, 3, 253, 254, 255]),
        nestedMessage: SingleFieldProtoTestMessage(
            value: "Hallo, das ist eine Sub-Nachricht."
        ),
        numberFloat: 12345.12345
    )
    
    let expectedComplexMsgWithOptionalsPartsSet: [UInt8] = [
        8, 199, 159, 255, 255, 255, 255, 255, 255, 255,
        1, 24, 1, 41, 88, 168, 53, 205, 143, 28, 200, 64,
        58, 6, 1, 2, 3, 253, 254, 255, 66, 36, 10, 34,
        72, 97, 108, 108, 111, 44, 32, 100, 97, 115,
        32, 105, 115, 116, 32, 101, 105, 110, 101, 32,
        83, 117, 98, 45, 78, 97, 99, 104, 114, 105, 99,
        104, 116, 46
    ]
    
    let complexMessageWithOptionalsPartsSet = ProtoComplexTestMessageWithOptionals(
        numberInt32: -12345,
        numberUint32: nil,
        numberBool: true,
        enumValue: nil,
        numberDouble: 12345.12345,
        content: nil,
        byteData: Data([1, 2, 3, 253, 254, 255]),
        nestedMessage: SingleFieldProtoTestMessage(
            value: "Hallo, das ist eine Sub-Nachricht."
        ),
        numberFloat: nil
    )
    
    
    func testEncodeComplexMessage() throws {
        try _testImpl(
            complexMessage,
            expectedBytes: expectedComplexMessageBytes,
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(UInt64(bitPattern: -12345)), fieldLength: 11)],
                2: [.init(tag: 2, keyOffset: 11, valueOffset: 12, valueInfo: .varInt(12345), fieldLength: 3)],
                4: [.init(tag: 4, keyOffset: 14, valueOffset: 15, valueInfo: .varInt(1), fieldLength: 2)],
                5: [.init(tag: 5, keyOffset: 16, valueOffset: 17, valueInfo: .varInt(2), fieldLength: 2)],
                8: [.init(tag: 8, keyOffset: 18, valueOffset: 19, valueInfo: ._64Bit(Double(12345.12345).bitPattern), fieldLength: 9)],
                9: [.init(tag: 9, keyOffset: 27, valueOffset: 28, valueInfo: .lengthDelimited(dataLength: 11, dataOffset: 1), fieldLength: 13)],
                10: [.init(tag: 10, keyOffset: 40, valueOffset: 41, valueInfo: .lengthDelimited(dataLength: 6, dataOffset: 1), fieldLength: 8)],
                11: [.init(tag: 11, keyOffset: 48, valueOffset: 49, valueInfo: .lengthDelimited(dataLength: 36, dataOffset: 1), fieldLength: 38)],
                14: [.init(tag: 14, keyOffset: 86, valueOffset: 87, valueInfo: ._32Bit(Float(12345.12345).bitPattern), fieldLength: 5)]
            ]
        )
    }
    
    func testEncodeComplexMessageWithOptionalsAllNil() throws {
        try _testImpl(
            ProtoComplexTestMessageWithOptionals(),
            expectedBytes: [],
            expectedFieldMapping: [:]
        )
    }
    
    func testEncodeComplexMessageWithOptionalsAllSet() throws {
        try _testImpl(
            complexMessage,
            expectedBytes: expectedComplexMessageBytes,
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(UInt64(bitPattern: -12345)), fieldLength: 11)],
                2: [.init(tag: 2, keyOffset: 11, valueOffset: 12, valueInfo: .varInt(12345), fieldLength: 3)],
                4: [.init(tag: 4, keyOffset: 14, valueOffset: 15, valueInfo: .varInt(1), fieldLength: 2)],
                8: [.init(tag: 8, keyOffset: 18, valueOffset: 19, valueInfo: ._64Bit(Double(12345.12345).bitPattern), fieldLength: 9)],
                5: [.init(tag: 5, keyOffset: 16, valueOffset: 17, valueInfo: .varInt(2), fieldLength: 2)],
                9: [.init(tag: 9, keyOffset: 27, valueOffset: 28, valueInfo: .lengthDelimited(dataLength: 11, dataOffset: 1), fieldLength: 13)],
                10: [.init(tag: 10, keyOffset: 40, valueOffset: 41, valueInfo: .lengthDelimited(dataLength: 6, dataOffset: 1), fieldLength: 8)],
                11: [.init(tag: 11, keyOffset: 48, valueOffset: 49, valueInfo: .lengthDelimited(dataLength: 36, dataOffset: 1), fieldLength: 38)],
                14: [.init(tag: 14, keyOffset: 86, valueOffset: 87, valueInfo: ._32Bit(Float(12345.12345).bitPattern), fieldLength: 5)]
            ]
        )
    }
    
    func testEncodeComplexMessageWithOptionalsPartiallySet() throws {
        let encoded = try ProtobufferEncoder().encode(complexMessageWithOptionalsPartsSet)
        try XCTAssertEqual(encoded, expectedComplexMsgWithOptionalsPartsSet)
        try _testImpl(
            complexMessageWithOptionalsPartsSet,
            expectedBytes: expectedComplexMsgWithOptionalsPartsSet,
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(UInt64(bitPattern: -12345)), fieldLength: 11)],
                3: [.init(tag: 3, keyOffset: 11, valueOffset: 12, valueInfo: .varInt(1), fieldLength: 2)],
                5: [.init(tag: 5, keyOffset: 13, valueOffset: 14, valueInfo: ._64Bit(Double(12345.12345).bitPattern), fieldLength: 9)],
                7: [.init(tag: 7, keyOffset: 22, valueOffset: 23, valueInfo: .lengthDelimited(dataLength: 6, dataOffset: 1), fieldLength: 8)],
                8: [.init(tag: 8, keyOffset: 30, valueOffset: 31, valueInfo: .lengthDelimited(dataLength: 36, dataOffset: 1), fieldLength: 38)]
            ]
        )
    }
    
    
    // MARK: Optional Encoding Tests
    
    func testEncodeSinglePositiveOptionalInt32() throws {
        let number: Int32? = 12345
        let encoded = try ProtobufferEncoder().encode(number)
        try XCTAssertEqual(encoded, [185, 96])
    }
    
    
    func testEncodePositiveOptionalInt32Message() throws {
        let number: Int32? = 12345
        let message = SingleFieldProtoTestMessage(value: number)
        let encoded = try ProtobufferEncoder().encode(message)
        try XCTAssertEqual(encoded, [8, 185, 96])
    }
    
    
    func testEncodeSingleOptionalString() throws {
        let content: String? = "Hello World"
        let encoded = try ProtobufferEncoder().encode(content)
        try XCTAssertEqual(encoded, [11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
    }
    
    
    func testEncodeOptionalStringMessage() throws {
        try _testImpl(
            SingleFieldProtoTestMessage<String?>(value: "Hello World"),
            expectedBytes: [10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100],
            expectedFieldMapping: [
                1: [.init(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 11, dataOffset: 1), fieldLength: 13)]
            ]
        )
    }
    
    
    func testRepeatedOptionalValueCoding() throws {
        let message = SingleFieldProtoTestMessage<[Bool?]>(value: [true, nil, true])
        XCTAssertThrowsError(try ProtobufferEncoder().encode(message)) { (error: Error) in
            let validationError = error as! ProtoValidationError
            XCTAssertEqual(validationError, .arrayOfOptionalsNotAllowed([Bool?].self))
        }
    }
    
    
    func testOptionalRepeatedValueCoding() throws {
        let message = SingleFieldProtoTestMessage<[Bool]?>(value: nil)
        XCTAssertThrowsError(try ProtobufferEncoder().encode(message)) { (error: Error) in
            let validationError = error as! ProtoValidationError
            XCTAssertEqual(validationError, .optionalArrayNotAllowed([Bool]?.self))
        }
    }
}
