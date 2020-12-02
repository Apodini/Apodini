//
//  ProtobufDecoderTests.swift
//  
//
//  Created by Moritz Schüll on 26.11.20.
//

import Foundation
import XCTest
@testable import ProtobufferCoding

struct Message<T: Codable>: Codable {
    var content: T
    enum CodingKeys: Int, CodingKey {
        case content = 1
    }
}

struct ComplexMessage: Codable {
    var numberInt32: Int32
    var numberUint32: UInt32
    var numberBool: Bool
    var enumValue: Int32
    var numberDouble: Double
    var content: String
    var byteData: Data
    var nestedMessage: Message<String>
    var numberFloat: Float

    enum CodingKeys: String, CodingKey, ProtoCodingKey {
        case numberInt32
        case numberUint32
        case numberBool
        case enumValue
        case numberDouble
        case content
        case byteData
        case nestedMessage
        case numberFloat

        static func protoRawValue(_ key: CodingKey) throws -> Int {
            switch key {
            case CodingKeys.numberInt32:
                return 1
            case numberUint32:
                return 2
            case numberBool:
                return 4
            case enumValue:
                return 5
            case numberDouble:
                return 8
            case content:
                return 9
            case byteData:
                return 10
            case nestedMessage:
                return 11
            case numberFloat:
                return 14
            default:
                throw ProtoError.unknownCodingKey(key)
            }
        }
    }
}

class ProtobufDecoderTests: XCTestCase {
    func testDecodePositiveInt32() throws {
        let positiveData = Data([8, 185, 96])
        let positiveExpected: Int32 = 12345

        let message = try ProtoDecoder().decode(Message<Int32>.self, from: positiveData)
        XCTAssertEqual(message.content, positiveExpected, "testDecodePositiveInt32")
    }

    func testDecodeNegativeInt32() throws {
        let negativeData = Data([8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1])
        let negativeExpected: Int32 = -12345

        let message = try ProtoDecoder().decode(Message<Int32>.self, from: negativeData)
        XCTAssertEqual(message.content, negativeExpected, "testDecodeNegativeInt32")
    }

    func testDecodeUInt32() throws {
        let data = Data([8, 185, 96])
        let expected: UInt32 = 12345

        let message = try ProtoDecoder().decode(Message<UInt32>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeUInt32")
    }

    func testDecodeBool() throws {
        let data = Data([8, 1])

        let message = try ProtoDecoder().decode(Message<Bool>.self, from: data)
        XCTAssertEqual(message.content, true, "testDecodeBool")
    }

    func testDecodeDouble() throws {
        let data = Data([9, 88, 168, 53, 205, 143, 28, 200, 64])
        let expected: Double = 12345.12345

        let message = try ProtoDecoder().decode(Message<Double>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeDouble")
    }

    func testDecodeFloat() throws {
        let data = Data([13, 126, 228, 64, 70])
        let expected: Float = 12345.12345

        let message = try ProtoDecoder().decode(Message<Float>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeFloat")
    }

    func testDecodeString() throws {
        let data = Data([10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
        let expected: String = "Hello World"

        let message = try ProtoDecoder().decode(Message<String>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeString")
    }

    func testDecodeBytes() throws {
        let data = Data([10, 6, 1, 2, 3, 253, 254, 255])
        let expected = Data([1, 2, 3, 253, 254, 255])

        let message = try ProtoDecoder().decode(Message<Data>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeBytes")
    }

    func testDecodeRepeatedBool() throws {
        let data = Data([10, 3, 1, 0, 1])
        let expected = [true, false, true]

        let message = try ProtoDecoder().decode(Message<[Bool]>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeRepeatedBool")
    }

    func testDecodeRepeatedInt32() throws {
        let data = Data([10, 5, 1, 2, 3, 4, 5])
        let expected: [Int32] = [1, 2, 3, 4, 5]

        let message = try ProtoDecoder().decode(Message<[Int32]>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeRepeatedInt32")
    }

    func testDecodeRepeatedInt64() throws {
        let data = Data([
                            10, 30, 195, 144, 236, 143, 247, 35,
                            196, 144, 236, 143, 247, 35, 197, 144,
                            236, 143, 247, 35, 198, 144, 236, 143,
                            247, 35, 199, 144, 236, 143, 247, 35
        ])
        let expected: [Int64] = [1234567891011, 1234567891012, 1234567891013, 1234567891014, 1234567891015]

        let message = try ProtoDecoder().decode(Message<[Int64]>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeRepeatedInt64")
    }

    func testDecodeRepeatedFloat() throws {
        let data = Data([
                            10, 20, 250, 62, 246, 66, 207, 119,
                            246, 66, 164, 176, 246, 66, 121, 233,
                            246, 66, 78, 34, 247, 66
        ])
        let expected: [Float] = [123.123, 123.234, 123.345, 123.456, 123.567]

        let message = try ProtoDecoder().decode(Message<[Float]>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeRepeatedFloat")
    }

    func testDecodeRepeatedDouble() throws {
        let data = Data([
                            10, 24, 117, 107, 126, 84, 52, 111,
                            157, 65, 219, 209, 228, 84, 52, 111,
                            157, 65, 66, 56, 75, 85, 52, 111,
                            157, 65
        ])
        let expected: [Double] = [123456789.123456789, 123456789.223456789, 123456789.323456789]

        let message = try ProtoDecoder().decode(Message<[Double]>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeRepeatedDouble")
    }

    func testDecodeRepeatedUInt32() throws {
        let data = Data([10, 5, 1, 2, 3, 4, 5])
        let expected: [UInt32] = [1, 2, 3, 4, 5]

        let message = try ProtoDecoder().decode(Message<[UInt32]>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeRepeatedUInt32")
    }

    func testDecodeRepeatedData() throws {
        let data = Data([10, 2, 1, 2, 10, 2, 3, 4, 10, 2, 5, 6])
        let bytes1: [UInt8] = [1, 2]
        let bytes2: [UInt8] = [3, 4]
        let bytes3: [UInt8] = [5, 6]
        let expected: [Data] = [Data(bytes1), Data(bytes2), Data(bytes3)]

        let message = try ProtoDecoder().decode(Message<[Data]>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeRepeatedData")
    }

    func testDecodeRepeatedString() throws {
        let data = Data([10, 4, 101, 105, 110, 115, 10, 4, 122, 119, 101, 105, 10, 4, 100, 114, 101, 105])
        let expected = ["eins", "zwei", "drei"]

        let message = try ProtoDecoder().decode(Message<[String]>.self, from: data)
        XCTAssertEqual(message.content, expected, "testDecodeRepeatedString")
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

    let expectedComplexMessage = ComplexMessage(
        numberInt32: -12345,
        numberUint32: 12345,
        numberBool: true,
        enumValue: 2,
        numberDouble: 12345.12345,
        content: "Hello World",
        byteData: Data([1, 2, 3, 253, 254, 255]),
        nestedMessage: Message(
            content: "Hallo, das ist eine Sub-Nachricht."
        ),
        numberFloat: 12345.12345
    )

    func testDecodeComplexMessage() throws {
        let message = try ProtoDecoder().decode(ComplexMessage.self, from: dataComplexMessage)
        XCTAssertEqual(message.numberInt32, expectedComplexMessage.numberInt32, "testDecodeComplexInt32")
        XCTAssertEqual(message.numberUint32, expectedComplexMessage.numberUint32, "testDecodeComplexUInt32")
        XCTAssertEqual(message.numberBool, expectedComplexMessage.numberBool, "testDecodeComplexBool")
        XCTAssertEqual(message.enumValue, expectedComplexMessage.enumValue, "testDecodeComplexEnum")
        XCTAssertEqual(message.numberDouble, expectedComplexMessage.numberDouble, "testDecodeComplexDouble")
        XCTAssertEqual(message.content, expectedComplexMessage.content, "testDecodeComplexString")
        XCTAssertEqual(message.byteData, expectedComplexMessage.byteData, "testDecodeComplexBytes")
        XCTAssertEqual(message.nestedMessage.content,
                       expectedComplexMessage.nestedMessage.content,
                       "testDecodeComplexString")
        XCTAssertEqual(message.numberFloat, expectedComplexMessage.numberFloat, "testDecodeComplexFloat")
    }

    /// Decodes an unknown type (which means, no Decodable struct is known),
    /// by using an unkeyed container.
    func testDecodeUnknownComplexMessage() throws {
        var container = try ProtoDecoder().decode(from: dataComplexMessage)
        XCTAssertEqual(try container.decode(Int32.self),
                       expectedComplexMessage.numberInt32,
                       "testDecodeUnknownComplexInt32")
        XCTAssertEqual(try container.decode(UInt32.self),
                       expectedComplexMessage.numberUint32,
                       "testDecodeUnknownComplexUInt32")
        XCTAssertEqual(try container.decode(Bool.self),
                       expectedComplexMessage.numberBool,
                       "testDecodeUnknownComplexBool")
        XCTAssertEqual(try container.decode(Int32.self),
                       expectedComplexMessage.enumValue,
                       "testDecodeUnknownComplexEnum")
        XCTAssertEqual(try container.decode(Double.self),
                       expectedComplexMessage.numberDouble,
                       "testDecodeUnknownComplexDouble")
        XCTAssertEqual(try container.decode(String.self),
                       expectedComplexMessage.content,
                       "testDecodeUnknownComplexString")
        XCTAssertEqual(try container.decode(Data.self),
                       expectedComplexMessage.byteData,
                       "testDecodeUnknownComplexBytes")
        var nestedContainer = try container.nestedUnkeyedContainer()
        XCTAssertEqual(try nestedContainer.decode(String.self),
                       expectedComplexMessage.nestedMessage.content,
                       "testDecodeUnknownComplexString")
        XCTAssertEqual(try container.decode(Float.self),
                       expectedComplexMessage.numberFloat,
                       "testDecodeUnknownComplexFloat")
    }
}
