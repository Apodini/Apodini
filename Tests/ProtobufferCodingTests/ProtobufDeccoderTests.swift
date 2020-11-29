//
//  ProtobufDecoderTests.swift
//  
//
//  Created by Moritz Schüll on 26.11.20.
//

import Foundation
import XCTest
@testable import ProtobufferCoding


class ProtobufDecoderTests: XCTestCase {

    struct Message<T: Codable>: Codable {
        var content: T
        enum CodingKeys: Int, CodingKey {
            case content = 1
        }
    }

    struct ComplexMessage: Codable {
        public var numberInt32: Int32
        public var numberUint32: UInt32
        public var numberBool: Bool
        public var enumValue: Int32
        public var numberDouble: Double
        public var content: String
        public var byteData: Data
        public var nestedMessage: Message<String>
        public var numberFloat: Float

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

    func testDecodeComplexMessage() throws {
        let data = Data([8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1,
                         16, 185, 96, 32, 1, 40, 2, 65, 88, 168, 53, 205,
                         143, 28, 200, 64, 74, 11, 72, 101, 108, 108, 111,
                         32, 87, 111, 114, 108, 100, 82, 6, 1, 2, 3, 253, 254,
                         255, 90, 36, 10, 34, 72, 97, 108, 108, 111, 44, 32,
                         100, 97, 115, 32, 105, 115, 116, 32, 101, 105, 110,
                         101, 32, 83, 117, 98, 45, 78, 97, 99, 104, 114, 105,
                         99, 104, 116, 46, 117, 126, 228, 64, 70])

        let expected = ComplexMessage(
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

        let message = try ProtoDecoder().decode(ComplexMessage.self, from: data)
        XCTAssertEqual(message.numberInt32, expected.numberInt32, "testDecodeComplexInt32")
        XCTAssertEqual(message.numberUint32, expected.numberUint32, "testDecodeComplexUInt32")
        XCTAssertEqual(message.numberBool, expected.numberBool, "testDecodeComplexBool")
        XCTAssertEqual(message.enumValue, expected.enumValue, "testDecodeComplexEnum")
        XCTAssertEqual(message.numberDouble, expected.numberDouble, "testDecodeComplexDouble")
        XCTAssertEqual(message.content, expected.content, "testDecodeComplexString")
        XCTAssertEqual(message.byteData, expected.byteData, "testDecodeComplexBytes")
        XCTAssertEqual(message.nestedMessage.content, expected.nestedMessage.content, "testDecodeComplexString")
        XCTAssertEqual(message.numberFloat, expected.numberFloat, "testDecodeComplexFloat")
    }
}
