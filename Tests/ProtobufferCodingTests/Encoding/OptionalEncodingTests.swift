//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
import XCTest
@testable import ProtobufferCoding

class OptionalEncodingTests: XCTestCase {
    func testEncodeSinglePositiveOptionalInt32() throws {
        let expected = Data([8, 185, 96])
        let number: Int32? = 12345

        let encoded = try ProtobufferEncoder().encode(number)
        XCTAssertEqual(encoded, expected)
    }

    func testEncodePositiveOptionalInt32Message() throws {
        let expected = Data([8, 185, 96])
        let number: Int32? = 12345

        let message = ProtoTestMessage(content: number)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected)
    }

    func testEncodeSingleOptionalString() throws {
        let expected = Data([10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
        let content: String? = "Hello World"

        let encoded = try ProtobufferEncoder().encode(content)
        XCTAssertEqual(encoded, expected)
    }

    func testEncodeOptionalStringMessage() throws {
        let expected = Data([10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
        let content: String? = "Hello World"

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected)
    }

    func testEncodeRepeatedOptionalBoolMessage() throws {
        let expected = Data([10, 2, 1, 1])
        let content = [true, nil, true]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected)
    }

    func testEncodeRepeatedOptionalInt() throws {
        let expected = Data([10, 4, 1, 2, 4, 5])
        let content: [Int?] = [1, 2, nil, 4, 5]

        let encoded = try ProtobufferEncoder().encode(content)
        XCTAssertEqual(encoded, expected)
    }

    func testEncodeRepeatedOptionalInt32() throws {
        let expected = Data([10, 4, 1, 2, 4, 5])
        let content: [Int32?] = [1, 2, nil, 4, 5]

        let encoded = try ProtobufferEncoder().encode(content)
        XCTAssertEqual(encoded, expected)
    }

    func testEncodeRepeatedOptionalInt32Message() throws {
        let expected = Data([10, 4, 1, 2, 4, 5])
        let content: [Int32?] = [1, 2, nil, 4, 5]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected)
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
        XCTAssertEqual(encoded, expected)
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
        XCTAssertEqual(encoded, expected)
    }

    func testEncodeRepeatedOptionalUIntMessage() throws {
        let expected = Data([10, 4, 1, 2, 4, 5])
        let content: [UInt?] = [1, 2, nil, 4, 5]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected)
    }

    func testEncodeRepeatedOptionalUInt32Message() throws {
        let expected = Data([10, 4, 1, 2, 3, 4])
        let content: [UInt32?] = [1, 2, 3, 4, nil]

        let message = ProtoTestMessage(content: content)
        let encoded = try ProtobufferEncoder().encode(message)
        XCTAssertEqual(encoded, expected)
    }
}
