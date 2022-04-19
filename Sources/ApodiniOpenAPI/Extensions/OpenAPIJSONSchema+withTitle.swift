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
    // swiftlint:disable:next cyclomatic_complexity
    // swiftlint:disable pattern_matching_keywords
    func with(title: String) -> JSONSchema {
        switch self {
        case .boolean(let context):
            return .boolean(context.with(title: title))
        case .object(let contextA, let contextB):
            return .object(contextA.with(title: title), contextB)
        case .array(let contextA, let contextB):
            return .array(contextA.with(title: title), contextB)
        case .number(let context, let contextB):
            return .number(context.with(title: title), contextB)
        case .integer(let context, let contextB):
            return .integer(context.with(title: title), contextB)
        case .string(let context, let contextB):
            return .string(context.with(title: title), contextB)
        case .fragment(let context):
            return .fragment(context.with(title: title))
        case .all(of: let fragments, core: let core):
            return .all(of: fragments, core: core.with(title: title))
        case .one(of: let schemas, core: let core):
            return .one(of: schemas, core: core.with(title: title))
        case .any(of: let schemas, core: let core):
            return .any(of: schemas, core: core.with(title: title))
        case .not(let schema, core: let core):
            return .not(schema, core: core.with(title: title))
        case .reference:
            return self
        }
    }
    // swiftlint:enable all
}

extension JSONSchema.CoreContext {
    /// Return this context with the given title
    public func with(title: String) -> JSONSchema.CoreContext<Format> {
        .init(
            format: format,
            required: required,
            nullable: nullable,
            permissions: permissions,
            deprecated: deprecated,
            title: title,
            description: description,
            discriminator: discriminator,
            externalDocs: externalDocs,
            allowedValues: allowedValues,
            defaultValue: defaultValue,
            example: example
        )
    }
}

