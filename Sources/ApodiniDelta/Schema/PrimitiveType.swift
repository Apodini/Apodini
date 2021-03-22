//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

enum PrimitiveType: String, RawRepresentable, Codable {
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

    case unknown

    init(_ type: Any.Type) {
        self = PrimitiveType(rawValue: "\(type)") ?? .unknown

        precondition(self != .unknown, "'isSupportedScalarType' method has been updated with \(type), but the update is not reflected in 'PrimitiveType' enum yet.")
    }
}

extension PrimitiveType: CustomStringConvertible {

    var description: String { rawValue }
}
