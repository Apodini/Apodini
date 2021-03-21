//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

enum PrimitiveType: String, Codable {
    case int, int32, int64
    case uint, uint32, uint64
    case bool
    case string
    case double
    case float

    case uuid

    case na

    init(_ type: Any.Type) {
        if type.self == Int.self {
            self = .int
        } else if type.self == Int32.self {
            self = .int32
        } else if type.self == Int64.self {
            self = .int64
        } else if type.self == UInt.self {
            self = .uint
        } else if type.self == UInt32.self {
            self = .uint32
        } else if type.self == UInt64.self {
            self = .uint64
        } else if type.self == Bool.self {
            self = .bool
        } else if type.self == String.self {
            self = .string
        } else if type.self == Double.self {
            self = .double
        } else if type.self == Float.self {
            self = .float
        } else if type.self == UUID.self {
            self = .uuid
        } else {
            self = .na
        }

        precondition(self != .na, "'isSupportedScalarType' method has been updated with \(type), but the update is not reflected in 'PrimitiveType' enum yet.")
    }
}

extension PrimitiveType: CustomStringConvertible {

    var description: String {
        switch self {
        case .int:
            return "Int"
        case .int32:
            return "Int32"
        case .int64:
            return "Int64"
        case .uint:
            return "UInt"
        case .uint32:
            return "UInt32"
        case .uint64:
            return "UInt64"
        case .bool:
            return "Bool"
        case .string:
            return "String"
        case .double:
            return "Double"
        case .float:
            return "Float"
        case .uuid:
            return "UUID"
        case .na:
            return "NA"
        }
    }
}
