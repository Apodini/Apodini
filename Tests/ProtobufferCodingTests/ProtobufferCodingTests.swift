//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import Foundation
import NIO
@testable import ProtobufferCoding


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
        let input = SimpleStructWithIntProperty(value: 52)
        let encoded = try ProtobufferEncoder().encode(input)
        try XCTAssertEqual(encoded, [0b1000, 52])
        XCTAssertEqual(try ProtobufMessageLayoutDecoder.getFields(in: encoded), ProtobufFieldsMapping([
            1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(52), fieldLength: 2)]
        ]))
        try assertDecodedMatches(encoded, input)
    }
    
    
    func testSimpleStruct_Float() throws {
        struct SimpleStructWithFloatProperty: Codable, Equatable {
            let value: Float
        }
        let input = SimpleStructWithFloatProperty(value: 3.141592654)
        let encoded = try ProtobufferEncoder().encode(input)
        try XCTAssertEqual(encoded, [0b1101, 219, 15, 73, 64])
        XCTAssertEqual(try ProtobufMessageLayoutDecoder.getFields(in: encoded), ProtobufFieldsMapping([
            1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: ._32Bit(1078530011), fieldLength: 5)]
        ]))
        print((3.141592654 as Float).bitPattern)
        try assertDecodedMatches(encoded, input)
    }
    
    
    func testSimpleStruct_Double() throws {
        struct SimpleStructWithDoubleProperty: Codable, Equatable {
            let value: Double
        }
        let input = SimpleStructWithDoubleProperty(value: 3.141592654) // TODO find some value that can be repersented as a double but not as a float!
        let encoded = try ProtobufferEncoder().encode(input)
        try XCTAssertEqual(encoded, [0b1001, 80, 69, 82, 84, 251, 33, 9, 64])
        XCTAssertEqual(try ProtobufMessageLayoutDecoder.getFields(in: encoded), ProtobufFieldsMapping([
            1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: ._64Bit(4614256656552969552), fieldLength: 9)]
        ]))
        try assertDecodedMatches(encoded, input)
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
            12: [ProtobufFieldInfo(tag: 12, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 11, dataOffset: 1), fieldLength: 13)]
        ]))
        try assertDecodedMatches(encoded, input)
    }
    
    
    func testGenericStruct() throws {
        try _testImpl(
            GenericSingleFieldMessage<String>(value: "Hello there"),
            expectedBytes: [0b1010, 11, 72, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101],
            expectedFieldMapping: [
                1: [ProtobufFieldInfo(tag: 1, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 11, dataOffset: 1), fieldLength: 13)]
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
    
    
    func _testImpl<T: Codable & Equatable>(_ input: T, expectedBytes: [UInt8], expectedFieldMapping: ProtobufFieldsMapping) throws {
        let encoded = try ProtobufferEncoder().encode(input)
        try XCTAssertEqual(encoded, expectedBytes)
        if !(expectedFieldMapping.isEmpty && encoded.readableBytes == 0) {
            XCTAssertEqual(try ProtobufMessageLayoutDecoder.getFields(in: encoded), expectedFieldMapping)
        }
        if !(expectedBytes.isEmpty && encoded.readableBytes == 0) {
            try assertDecodedMatches(encoded, input)
        }
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
        try imp(Double.self, emptyValue: 0)
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
        
        func ascii(_ char: Character) -> UInt8 {
            char.asciiValue!
        }
        
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
        
        func ascii(_ char: Character) -> UInt8 {
            char.asciiValue!
        }
        
        let bytes: [UInt8] = [
            0b1010, 5, ascii("L"), ascii("u"), ascii("k"), ascii("a"), ascii("s"),
            0b10000, 52,
            0b1010, 4, ascii("P"), ascii("a"), ascii("u"), ascii("l"),
        ]
        
        let decoded = try ProtobufferDecoder().decode(Message.self, from: Data(bytes))
        XCTAssertEqual(decoded, Message(names: ["Lukas", "Paul"], number: 52))
    }
    
    
//    func testSimpleEnum() throws {
//        try _testImpl(
//            FieldDescriptorProto(
//                name: "value",
//                number: 1,
//                type: .TYPE_BOOL,
//                proto3Optional: false
//            ),
//            expectedBytes: [],
//            expectedFieldMapping: [
//                FieldDescriptorProto.CodingKeys.name.rawValue: [.init(
//                    tag: 0, keyOffset: 0, valueOffset: 1, valueInfo: .lengthDelimited(dataLength: 5, dataOffset: 1), fieldLength: 7
//                )],
//                FieldDescriptorProto.CodingKeys.number.rawValue: [.init(
//                    tag: 0, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(1), fieldLength: 7
//                )],
//                FieldDescriptorProto.CodingKeys.type.rawValue: [.init(
//                    tag: 0, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(FieldDescriptorProto.FieldType.TYPE_BOOL.rawValue), fieldLength: 7
//                )],
//                FieldDescriptorProto.CodingKeys.proto3Optional.rawValue: [.init(
//                    tag: 0, keyOffset: 0, valueOffset: 1, valueInfo: .varInt(0), fieldLength: 7
//                )],
//            ]
//        )
//    }
    
    
    func testDecodeGRPCReflectionInput() throws {
        // TODO collect some real-world reflection input and test against that
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
        //XCTAssertNoThrow(schema.informAboutType(Shape.self))
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
        XCTAssertEqual(protoType, .enumTy(name: .init(mangled: "[de.lukaskollmer].ProtobufferCodingTests.Proto2ValidShape"), enumType: Proto2ValidShape.self, cases: [
            .init(name: "square", value: 1),
            .init(name: "circle", value: 2),
            .init(name: "triangle", value: 3)
        ]))
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
}


struct SimpleStructWithIntProperty: Codable {
    let value: Int
}

struct SimpleStructWithMessageProperty: Codable {
    let message: Person
}





struct _TestFailingError: Swift.Error, LocalizedError {
    let message: String
    
    var errorDescription: String? {
        message
    }
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
