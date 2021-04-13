//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

extension PrimitiveType: ComparableProperty {}

enum PrimitiveType: String, RawRepresentable {
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

    init(_ type: Any.Type) {
        if let primitiveType = PrimitiveType(rawValue: "\(type)") {
            self = primitiveType
        } else {
            fatalError("A new conformance to 'Primitive' protocol added for \(type), but the update is not reflected in 'PrimitiveType' enum yet.")
        }
    }
    
    var swiftType: Any.Type {
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

extension PrimitiveType: CustomStringConvertible {
    public var description: String { rawValue }
}


extension PrimitiveType {
    var schemaName: SchemaName {
        .init(String(reflecting: swiftType))
    }
}
