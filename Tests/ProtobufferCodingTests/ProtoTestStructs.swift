//
//  ProtoTestStructs.swift
//  
//
//  Created by Moritz Schüll on 02.12.20.
//

import Foundation
@testable import ProtobufferCoding

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
