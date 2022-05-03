//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import OpenAPIKit
import ApodiniUtils
import ApodiniTypeInformation

extension JSONSchema {
    /// Returns a `JSONSchema` from any arbitrary type. If type information construction throws,
    /// `defaultSchema` which defaults to `.string` is returned. Complex types return a `.reference` schema.
    static func from(_ type: Any.Type, defaultSchema: JSONSchema = .string) -> JSONSchema {
        guard let typeInformation = try? TypeInformation(type: type) else {
            return defaultSchema
        }
        return .from(typeInformation: typeInformation)
    }
    
    static func from(typeInformation: TypeInformation) -> JSONSchema {
        switch typeInformation {
        case let .scalar(primitiveType):
            return from(primitiveType: primitiveType)
        case let .repeated(element):
            return .array(items: from(typeInformation: element))
        case let .dictionary(_, value):
            return .object(additionalProperties: .init(from(typeInformation: value)))
        case let .optional(wrappedValue):
            return from(typeInformation: wrappedValue).optionalSchemaObject()
        case let .enum(_, _, cases, _):
            let context = typeInformation.context
            return .string(allowedValues: cases.map { .init($0.name) })
                .evaluateModifications(containedIn: context) // enums only have limited support for Metadata modifications as they are strings
        case .object, .reference:
            return .reference(.component(named: typeInformation.jsonSchemaName()))
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    static func from(primitiveType: PrimitiveType) -> JSONSchema {
        switch primitiveType {
        // Null is a custom object of ApodiniTypeInformation that encodes nil
        case .null:
            return .string(defaultValue: AnyCodable(Null()))
        case .bool:
            return .boolean
        case .int:
            return .integer
        case .int32:
            return .integer(format: .int32)
        case .int64:
            return .integer(format: .int64)
        case .int8, .int16, .uint, .uint8, .uint16, .uint32, .uint64:
            return .integer(format: .other(primitiveType.rawValue))
        case .string:
            return .string
        case .double:
            return .number(format: .double)
        case .float:
            return .number(format: .float)
        case .url, .uuid:
            return .string(format: .other(primitiveType.rawValue))
        case .date:
            return .string(format: .date)
        case .data:
            return .string(format: .binary)
        }
    }
}
