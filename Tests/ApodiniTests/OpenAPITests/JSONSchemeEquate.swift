//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
@testable import OpenAPIKit

infix operator <=>: ComparisonPrecedence

protocol CustomEquate {
    static func <=> (lhs: Self, rhs: Self) -> Bool
}

extension JSONSchema: CustomEquate {
    // the default implementation of Equatable just returns false for AnyCodable, therefore this whole mess
    // swiftlint:disable:next cyclomatic_complexity
    static func <=> (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.boolean(lhsContext), .boolean(rhsContext)):
            return lhsContext <=> rhsContext
        case let (.number(lhsContext, lhsNumericContext), .number(rhsContext, rhsNumericContext)):
            return lhsContext <=> rhsContext && lhsNumericContext == rhsNumericContext
        case let (.integer(lhsContext, lhsIntegerContext), .integer(rhsContext, rhsIntegerContext)):
            return lhsContext <=> rhsContext && lhsIntegerContext == rhsIntegerContext
        case let (.string(lhsContext, lhsStringContext), .string(rhsContext, rhsStringContext)):
            return lhsContext <=> rhsContext && lhsStringContext == rhsStringContext
        case let (.object(lhsContext, lhsObjectContext), .object(rhsContext, rhsObjectContext)):
            return lhsContext <=> rhsContext && lhsObjectContext <=> rhsObjectContext
        case let (.array(lhsContext, lhsArrayContext), .array(rhsContext, rhsArrayContext)):
            return lhsContext <=> rhsContext && lhsArrayContext <=> rhsArrayContext

        case let (.all(lhsOf, lhsContext), .all(rhsOf, rhsContext)):
            return lhsOf <=> rhsOf && lhsContext <=> rhsContext
        case let (.one(lhsOf, lhsContext), .one(rhsOf, rhsContext)):
            return lhsOf <=> rhsOf && lhsContext <=> rhsContext
        case let (.any(lhsOf, lhsContext), .any(rhsOf, rhsContext)):
            return lhsOf <=> rhsOf && lhsContext <=> rhsContext
        case let (.not(lhsOf, lhsContext), .not(rhsOf, rhsContext)):
            return lhsOf <=> rhsOf && lhsContext <=> rhsContext

        case let(.reference(lhsReference), .reference(rhsReference)):
            return lhsReference == rhsReference
        case let (.fragment(lhsContext), .fragment(rhsContext)):
            return lhsContext == rhsContext
        default:
            return false
        }
    }
}

extension AnyCodable: CustomEquate {
    static func <=> (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        do {
            let lhsString = try encoder.encode(lhs)
            let rhsString = try encoder.encode(rhs)

            return lhsString == rhsString
        } catch {
            fatalError("Failed Equatable implementation: \(error)")
        }
    }
}

extension JSONSchema.CoreContext: CustomEquate {
    static func <=> (lhs: Self, rhs: Self) -> Bool {
        lhs.format == rhs.format
            && lhs.required == rhs.required
            && lhs._nullable == rhs._nullable
            && lhs._permissions == rhs._permissions
            && lhs._deprecated == rhs._deprecated
            && lhs.title == rhs.title
            && lhs.description == rhs.description
            && lhs.discriminator == rhs.discriminator
            && lhs.externalDocs <=> rhs.externalDocs
            && lhs.allowedValues <=> rhs.allowedValues
            && lhs.defaultValue <=> rhs.defaultValue
            && lhs.example <=> rhs.example
    }
}

extension JSONSchema.ObjectContext: CustomEquate {
    static func <=> (lhs: Self, rhs: Self) -> Bool {
        lhs.properties <=> rhs.properties
            && lhs.additionalProperties <=> rhs.additionalProperties
            && lhs.maxProperties == rhs.maxProperties
            && lhs._minProperties == rhs._minProperties
    }
}

extension JSONSchema.ArrayContext: CustomEquate {
    static func <=> (lhs: Self, rhs: Self) -> Bool {
        lhs.items <=> rhs.items
            && lhs.maxItems == rhs.maxItems
            && lhs._minItems == rhs._minItems
            && lhs._uniqueItems == rhs._uniqueItems
    }
}

extension Either: CustomEquate where A: Equatable, B: CustomEquate {
    static func <=> (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.a(lhsA), .a(rhsA)):
            return lhsA == rhsA
        case let (.b(lhsB), .b(rhsB)):
            return lhsB <=> rhsB
        default:
            return false
        }
    }
}

extension OpenAPI.ExternalDocumentation: CustomEquate {
    static func <=> (lhs: Self, rhs: Self) -> Bool {
        lhs.description == rhs.description
            && lhs.url == rhs.url
            && lhs.vendorExtensions <=> rhs.vendorExtensions
    }
}

extension Optional: CustomEquate where Wrapped: CustomEquate {
    static func <=> (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.some(lhsWrapped), .some(rhsWrapped)):
            return lhsWrapped <=> rhsWrapped
        default:
            return false
        }
    }
}

extension Array: CustomEquate where Element: CustomEquate {
    static func <=> (lhs: Self, rhs: Self) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }

        for index in lhs.indices
            where !(lhs[index] <=> rhs[index]) {
            return false
        }

        return true
    }
}

extension Dictionary: CustomEquate where Value: CustomEquate {
    static func <=> (lhs: Self, rhs: Self) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }

        for (key, lhsElement) in lhs {
            guard let rhsElement = rhs[key] else {
                return false
            }

            if !(lhsElement <=> rhsElement) {
                return false
            }
        }

        return true
    }
}
