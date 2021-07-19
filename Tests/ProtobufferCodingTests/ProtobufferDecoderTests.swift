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

class ProtobufferDecoderTests: XCTestCase {
    func testDecodePositiveInt() throws {
        let positiveData = Data([8, 185, 96])
        let positiveExpected: Int = 12345

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<Int>.self, from: positiveData)
        XCTAssertEqual(message.content, positiveExpected)
    }

    func testDecodeNegativeInt() throws {
        let negativeData = Data([8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1])
        let negativeExpected: Int = -12345

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<Int>.self, from: negativeData)
        XCTAssertEqual(message.content, negativeExpected)
    }

    func testDecodePositiveInt32() throws {
        let positiveData = Data([8, 185, 96])
        let positiveExpected: Int32 = 12345

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<Int32>.self, from: positiveData)
        XCTAssertEqual(message.content, positiveExpected)
    }

    func testDecodeNegativeInt32() throws {
        let negativeData = Data([8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1])
        let negativeExpected: Int32 = -12345

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<Int32>.self, from: negativeData)
        XCTAssertEqual(message.content, negativeExpected)
    }

    func testDecodeInt64() throws {
        let positiveData = Data([8, 185, 96])
        let positiveExpected: Int64 = 12345

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<Int64>.self, from: positiveData)
        XCTAssertEqual(message.content, positiveExpected)
    }

    func testDecodeOptionalNegativeInt32() throws {
        let negativeData = Data([8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1])
        let negativeExpected: Int32? = -12345

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<Int32?>.self, from: negativeData)
        XCTAssertEqual(message.content, negativeExpected)
    }

    func testDecodeUInt() throws {
        let data = Data([8, 185, 96])
        let expected: UInt = 12345

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<UInt>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeUInt32() throws {
        let data = Data([8, 185, 96])
        let expected: UInt32 = 12345

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<UInt32>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeUInt64() throws {
        let data = Data([8, 185, 96])
        let expected: UInt64 = 12345

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<UInt64>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeBool() throws {
        let data = Data([8, 1])

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<Bool>.self, from: data)
        XCTAssertEqual(message.content, true)
    }

    func testDecodeDouble() throws {
        let data = Data([9, 88, 168, 53, 205, 143, 28, 200, 64])
        let expected: Double = 12345.12345

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<Double>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeFloat() throws {
        let data = Data([13, 126, 228, 64, 70])
        let expected: Float = 12345.12345

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<Float>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeString() throws {
        let data = Data([10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
        let expected: String = "Hello World"

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<String>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeOptionalString() throws {
        let data = Data([10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
        let expected: String? = "Hello World"

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<String?>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeBytes() throws {
        let data = Data([10, 6, 1, 2, 3, 253, 254, 255])
        let expected = Data([1, 2, 3, 253, 254, 255])

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<Data>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedBool() throws {
        let data = Data([10, 3, 1, 0, 1])
        let expected = [true, false, true]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[Bool]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedInt() throws {
        let data = Data([10, 5, 1, 2, 3, 4, 5])
        let expected: [Int] = [1, 2, 3, 4, 5]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[Int]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedInt32() throws {
        let data = Data([10, 5, 1, 2, 3, 4, 5])
        let expected: [Int32] = [1, 2, 3, 4, 5]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[Int32]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedInt64() throws {
        let data = Data([
                            10, 30, 195, 144, 236, 143, 247, 35,
                            196, 144, 236, 143, 247, 35, 197, 144,
                            236, 143, 247, 35, 198, 144, 236, 143,
                            247, 35, 199, 144, 236, 143, 247, 35
        ])
        let expected: [Int64] = [1234567891011, 1234567891012, 1234567891013, 1234567891014, 1234567891015]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[Int64]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedFloat() throws {
        let data = Data([
                            10, 20, 250, 62, 246, 66, 207, 119,
                            246, 66, 164, 176, 246, 66, 121, 233,
                            246, 66, 78, 34, 247, 66
        ])
        let expected: [Float] = [123.123, 123.234, 123.345, 123.456, 123.567]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[Float]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedOptionalFloat() throws {
        let data = Data([
                            10, 20, 250, 62, 246, 66, 207, 119,
                            246, 66, 164, 176, 246, 66, 121, 233,
                            246, 66, 78, 34, 247, 66
        ])
        let expected: [Float?] = [123.123, 123.234, 123.345, 123.456, 123.567]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[Float?]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedDouble() throws {
        let data = Data([
                            10, 24, 117, 107, 126, 84, 52, 111,
                            157, 65, 219, 209, 228, 84, 52, 111,
                            157, 65, 66, 56, 75, 85, 52, 111,
                            157, 65
        ])
        let expected: [Double] = [123456789.123456789, 123456789.223456789, 123456789.323456789]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[Double]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedUInt() throws {
        let data = Data([10, 5, 1, 2, 3, 4, 5])
        let expected: [UInt] = [1, 2, 3, 4, 5]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[UInt]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedUInt32() throws {
        let data = Data([10, 5, 1, 2, 3, 4, 5])
        let expected: [UInt32] = [1, 2, 3, 4, 5]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[UInt32]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedUInt64() throws {
        let data = Data([10, 5, 1, 2, 3, 4, 5])
        let expected: [UInt64] = [1, 2, 3, 4, 5]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[UInt64]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedData() throws {
        let data = Data([10, 2, 1, 2, 10, 2, 3, 4, 10, 2, 5, 6])
        let bytes1: [UInt8] = [1, 2]
        let bytes2: [UInt8] = [3, 4]
        let bytes3: [UInt8] = [5, 6]
        let expected: [Data] = [Data(bytes1), Data(bytes2), Data(bytes3)]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[Data]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    func testDecodeRepeatedString() throws {
        let data = Data([10, 4, 101, 105, 110, 115, 10, 4, 122, 119, 101, 105, 10, 4, 100, 114, 101, 105])
        let expected = ["eins", "zwei", "drei"]

        let message = try ProtobufferDecoder().decode(ProtoTestMessage<[String]>.self, from: data)
        XCTAssertEqual(message.content, expected)
    }

    // MARK: Complex message
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

    let expectedComplexMessage = ProtoComplexTestMessage(
        numberInt32: -12345,
        numberUint32: 12345,
        numberBool: true,
        enumValue: 2,
        numberDouble: 12345.12345,
        content: "Hello World",
        byteData: Data([1, 2, 3, 253, 254, 255]),
        nestedMessage: ProtoTestMessage(
            content: "Hallo, das ist eine Sub-Nachricht."
        ),
        numberFloat: 12345.12345
    )

    func testDecodeComplexMessage() throws {
        let message = try ProtobufferDecoder().decode(ProtoComplexTestMessage.self, from: dataComplexMessage)
        XCTAssertEqual(message.numberInt32, expectedComplexMessage.numberInt32)
        XCTAssertEqual(message.numberUint32, expectedComplexMessage.numberUint32)
        XCTAssertEqual(message.numberBool, expectedComplexMessage.numberBool)
        XCTAssertEqual(message.enumValue, expectedComplexMessage.enumValue)
        XCTAssertEqual(message.numberDouble, expectedComplexMessage.numberDouble)
        XCTAssertEqual(message.content, expectedComplexMessage.content)
        XCTAssertEqual(message.byteData, expectedComplexMessage.byteData)
        XCTAssertEqual(message.nestedMessage.content,
                       expectedComplexMessage.nestedMessage.content)
        XCTAssertEqual(message.numberFloat, expectedComplexMessage.numberFloat)
    }

    /// Decodes an unknown type (which means, no Decodable struct is known),
    /// by using an unkeyed container.
    func testDecodeUnknownComplexMessage() throws {
        var container = try ProtobufferDecoder().decode(from: dataComplexMessage)
        XCTAssertEqual(try container.decode(Int32.self),
                       expectedComplexMessage.numberInt32)
        XCTAssertEqual(try container.decode(UInt32.self),
                       expectedComplexMessage.numberUint32)
        XCTAssertEqual(try container.decode(Bool.self),
                       expectedComplexMessage.numberBool)
        XCTAssertEqual(try container.decode(Int32.self),
                       expectedComplexMessage.enumValue)
        XCTAssertEqual(try container.decode(Double.self),
                       expectedComplexMessage.numberDouble)
        XCTAssertEqual(try container.decode(String.self),
                       expectedComplexMessage.content)
        XCTAssertEqual(try container.decode(Data.self),
                       expectedComplexMessage.byteData)
        var nestedContainer = try container.nestedUnkeyedContainer()
        XCTAssertEqual(try nestedContainer.decode(String.self),
                       expectedComplexMessage.nestedMessage.content)
        XCTAssertEqual(try container.decode(Float.self),
                       expectedComplexMessage.numberFloat)
    }
}
