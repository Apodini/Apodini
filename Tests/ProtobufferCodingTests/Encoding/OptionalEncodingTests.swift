//
//  OptionalEncodingTests.swift
//  
//
//  Created by Moritz Schüll on 19.01.21.
//

import Foundation
import XCTest
@testable import ProtobufferCoding

class OptionalEncodingTests: XCTestCase {
    func testEncodeSinglePositiveOptionalInt32() throws {
        let expected = Data([8, 185, 96])
        let number: Int32? = 12345

        let encoded = try ProtobufferEncoder().encode(number)
        XCTAssertEqual(encoded, expected, "testEncodeSinglePositiveOptionalInt32")
    }

    func testEncodePositiveOptionalInt32Message() throws {
        let expected = Data([8, 185, 96])
        let number: Int32? = 12345

        let message = ProtoTestMessage(content: number)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodePositiveOptionalInt32Message")
    }

    func testEncodeSingleOptionalString() throws {
        let expected = Data([10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
        let content: String? = "Hello World"

        let encoded = try ProtobufferEncoder().encode(content)
        XCTAssertEqual(encoded, expected, "testEncodeSingleOptionalString")
    }

    func testEncodeOptionalStringMessage() throws {
        let expected = Data([10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
        let content: String? = "Hello World"

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeOptionalStringMessage")
    }

    func testEncodeRepeatedOptionalBoolMessage() throws {
        let expected = Data([10, 2, 1, 1])
        let content = [true, nil, true]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedOptionalBoolMessage")
    }

    func testEncodeRepeatedOptionalInt() throws {
        let expected = Data([10, 4, 1, 2, 4, 5])
        let content: [Int?] = [1, 2, nil, 4, 5]

        let encoded = try ProtobufferEncoder().encode(content)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedOptionalInt")
    }

    func testEncodeRepeatedOptionalInt32() throws {
        let expected = Data([10, 4, 1, 2, 4, 5])
        let content: [Int32?] = [1, 2, nil, 4, 5]

        let encoded = try ProtobufferEncoder().encode(content)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedOptionalInt32")
    }

    func testEncodeRepeatedOptionalInt32Message() throws {
        let expected = Data([10, 4, 1, 2, 4, 5])
        let content: [Int32?] = [1, 2, nil, 4, 5]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedOptionalInt32Message")
    }

    func testEncodeRepeatedOptionalFloatMessage() throws {
        let expected = Data([
                                10, 16, 250, 62, 246, 66, 207, 119,
                                246, 66, 121, 233,
                                246, 66, 78, 34, 247, 66
        ])
        let content: [Float?] = [123.123, 123.234, nil, 123.456, 123.567]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedOptionalFloatMessage")
    }

    func testEncodeRepeatedOptionalDoubleMessage() throws {
        let expected = Data([
                                10, 16, 117, 107, 126, 84, 52, 111,
                                157, 65, 219, 209, 228, 84, 52, 111,
                                157, 65
        ])
        let content: [Double?] = [123456789.123456789, 123456789.223456789, nil]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedOptionalDoubleMessage")
    }

    func testEncodeRepeatedOptionalUIntMessage() throws {
        let expected = Data([10, 4, 1, 2, 4, 5])
        let content: [UInt?] = [1, 2, nil, 4, 5]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedOptionalUIntMessage")
    }

    func testEncodeRepeatedOptionalUInt32Message() throws {
        let expected = Data([10, 4, 1, 2, 3, 4])
        let content: [UInt32?] = [1, 2, 3, 4, nil]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected, "testEncodeRepeatedOptionalUInt32Message")
    }
}
