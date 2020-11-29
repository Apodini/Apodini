//
//  ProtobufEncoderTests.swift
//  
//
//  Created by Moritz Schüll on 29.11.20.
//

import Foundation
import XCTest
@testable import ProtobufferCoding


class ProtobufEncoderTests: XCTestCase {

    struct Message<T: Codable>: Codable {
        var content: T
        enum CodingKeys: Int, CodingKey {
            case content = 1
        }
    }

    func testEncodeInt32() throws {
        let positiveData = Data([8, 185, 96])
        let positiveOriginal: Int32 = 12345
        let negativeData = Data([8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1])
        let negativeOriginal: Int32 = -12345

        let message1 = Message(content: positiveOriginal)
        let positiveEncoded = try ProtoEncoder().encode(message1)
        XCTAssertEqual(positiveEncoded, positiveData, "testEncodePositiveInt32")

        let message2 = Message(content: negativeOriginal)
        let negativeEncoded = try ProtoEncoder().encode(message2)
        XCTAssertEqual(negativeEncoded, negativeData, "testEncodeNegativeInt32")
    }

    func testEncodeUInt32() throws {
        let data = Data([8, 185, 96])
        let original: UInt32 = 12345

        let message = Message(content: original)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, data, "testEncodeUInt32")
    }

    func testDecodeBool() throws {
        let data = Data([8, 1])

        let message = Message(content: true)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, data, "testEncodeBool")
    }

    func testDecodeDouble() throws {
        let data = Data([9, 88, 168, 53, 205, 143, 28, 200, 64])
        let original: Double = 12345.12345

        let message = Message(content: original)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, data, "testEncodeDouble")
    }

    func testDecodeFloat() throws {
        let data = Data([13, 126, 228, 64, 70])
        let original: Float = 12345.12345

        let message = Message(content: original)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, data, "testEncodeFloat")
    }

    func testDecodeString() throws {
        let data = Data([10, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100])
        let original: String = "Hello World"

        let message = Message(content: original)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, data, "testEncodeString")
    }

    func testDecodeBytes() throws {
        let data = Data([10, 6, 1, 2, 3, 253, 254, 255])
        let original = Data([1, 2, 3, 253, 254, 255])

        let message = Message(content: original)
        let encoded = try ProtoEncoder().encode(message)
        XCTAssertEqual(encoded, data, "testEncodeBytes")
    }

    func testDecodeComplexMessage() throws {
        let data = Data([8, 199, 159, 255, 255, 255, 255, 255, 255, 255, 1, 16, 185, 96, 32, 1, 40, 2, 65, 88, 168, 53, 205, 143, 28, 200, 64, 74, 11, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 82, 6, 1, 2, 3, 253, 254, 255, 90, 36, 10, 34, 72, 97, 108, 108, 111, 44, 32, 100, 97, 115, 32, 105, 115, 116, 32, 101, 105, 110, 101, 32, 83, 117, 98, 45, 78, 97, 99, 104, 114, 105, 99, 104, 116, 46, 117, 126, 228, 64, 70])

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
                case numberInt32 = "numberInt32"
                case numberUint32 = "numberUint32"
                case numberBool = "numberBool"
                case enumValue = "enumValue"
                case numberDouble = "numberDouble"
                case content = "content"
                case byteData = "byteData"
                case nestedMessage = "nestedMessage"
                case numberFloat = "numberFloat"

                static func mapCodingKey(_ key: CodingKey) throws -> Int? {
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

        let original = ComplexMessage(
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

        let encoded = try ProtoEncoder().encode(original)
        XCTAssertEqual(encoded, data, "testEncodeComplexMessage")
    }
}
