//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
import OpenAPIKit

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
