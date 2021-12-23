//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import ProtobufferCoding
import Foundation


struct GenericSingleFieldMessage<T: Codable>: Codable {
    let value: T
}

extension GenericSingleFieldMessage: Equatable where T: Equatable {}
extension GenericSingleFieldMessage: Hashable where T: Hashable {}


struct SingleFieldProtoTestMessage<T: Codable & Equatable>: Codable & Equatable & ProtobufMessage {
    let value: T
}


struct ProtoComplexTestMessage: Codable, Equatable {
    var numberInt32: Int32
    var numberUint32: UInt32
    var numberBool: Bool
    var enumValue: Int32
    var numberDouble: Double
    var content: String
    var byteData: Data
    var nestedMessage: SingleFieldProtoTestMessage<String>
    var numberFloat: Float

    enum CodingKeys: Int, ProtobufMessageCodingKeys {
        case numberInt32 = 1
        case numberUint32 = 2
        case numberBool = 4
        case enumValue = 5
        case numberDouble = 8
        case content = 9
        case byteData = 10
        case nestedMessage = 11
        case numberFloat = 14
    }
}


struct ProtoComplexTestMessageWithOptionals: Codable, Equatable {
    var numberInt32: Int32?
    var numberUint32: UInt32?
    var numberBool: Bool? // swiftlint:disable:this discouraged_optional_boolean
    var enumValue: Int32?
    var numberDouble: Double?
    var content: String?
    var byteData: Data?
    var nestedMessage: SingleFieldProtoTestMessage<String>?
    var numberFloat: Float?
}
