//
// Created by Lorena Schlesinger on 03.01.21.
//

@_implementationOnly import OpenAPIKit
import Foundation

extension JSONSchema {
    static func from<T>(_ type: T, defaultType: JSONSchema = .string) -> JSONSchema {
        switch type {
        case is Int.Type:
            return .integer
        case is Bool.Type:
            return .boolean
        case is String.Type:
            return .string
        case is Double.Type:
            return .number(format: .double)
        case is Date.Type:
            return .string(format: .date)
        case is UUID.Type:
            return .string(format: .other("uuid"))
        default:
            return defaultType
        }
    }
}
