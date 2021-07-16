//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
@testable import ProtobufferCoding

// swiftlint:disable discouraged_optional_boolean
struct ProtoTestMessage<T: Codable>: Codable {
    var content: T
    enum CodingKeys: Int, CodingKey {
        case content = 1
    }
}

struct ProtoComplexTestMessage: Codable {
    var numberInt32: Int32
    var numberUint32: UInt32
    var numberBool: Bool
    var enumValue: Int32
    var numberDouble: Double
    var content: String
    var byteData: Data
    var nestedMessage: ProtoTestMessage<String>
    var numberFloat: Float

    enum CodingKeys: String, ProtobufferCodingKey {
        case numberInt32
        case numberUint32
        case numberBool
        case enumValue
        case numberDouble
        case content
        case byteData
        case nestedMessage
        case numberFloat

        var protoRawValue: Int {
            switch self {
            case CodingKeys.numberInt32:
                return 1
            case CodingKeys.numberUint32:
                return 2
            case CodingKeys.numberBool:
                return 4
            case CodingKeys.enumValue:
                return 5
            case CodingKeys.numberDouble:
                return 8
            case CodingKeys.content:
                return 9
            case CodingKeys.byteData:
                return 10
            case CodingKeys.nestedMessage:
                return 11
            case CodingKeys.numberFloat:
                return 14
            }
        }
    }
}

struct ProtoComplexTestMessageWithOptionals: Codable {
    var numberInt32: Int32?
    var numberUint32: UInt32?
    var numberBool: Bool?
    var enumValue: Int32?
    var numberDouble: Double?
    var content: String?
    var byteData: Data?
    var nestedMessage: ProtoTestMessage<String>?
    var numberFloat: Float?
}
