//
//  TypeInfo.swift
//  
//
//  Created by Paul Schmiedmayer on 1/13/21.
//

import Foundation

/// Whether the type is a supported scalar type
public func isSupportedScalarType(_ type: Any.Type) -> Bool {
    PrimitiveType(type) != nil
}

public enum PrimitiveType: String, RawRepresentable {
    case int = "Int"
    case int32 = "Int32"
    case int64 = "Int64"
    case uint = "UInt"
    case uint32 = "UInt32"
    case uint64 = "UInt64"
    case bool = "Bool"
    case string = "String"
    case double = "Double"
    case float = "Float"
    case uuid = "UUID"

    public init?(_ type: Any.Type) {
        if let primitiveType = PrimitiveType(rawValue: "\(type)") {
            self = primitiveType
        } else {
            return nil
        }
    }
    
    public var swiftType: Any.Type {
        switch self {
        case .int: return Int.self
        case .int32: return Int32.self
        case .int64: return Int64.self
        case .uint: return UInt.self
        case .uint32: return UInt32.self
        case .uint64: return UInt64.self
        case .bool: return Bool.self
        case .string: return String.self
        case .double: return Double.self
        case .float: return Float.self
        case .uuid: return UUID.self
        }
    }
}
