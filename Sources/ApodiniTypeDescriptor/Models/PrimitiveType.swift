//
//  File.swift
//  
//
//  Created by Eldi Cano on 12.04.21.
//

import Foundation

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

    init?(_ type: Any.Type) {
        if let primitiveType = PrimitiveType(rawValue: "\(type)") {
            self = primitiveType
        } else {
            return nil
        }
    }
}
