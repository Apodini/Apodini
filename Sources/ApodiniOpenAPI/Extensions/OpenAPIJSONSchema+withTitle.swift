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
    func with(title: String) -> JSONSchema {
        switch self {
        case let .boolean(context):
            return .boolean(context.with(title: title))
        case let .object(contextA, contextB):
            return .object(contextA.with(title: title), contextB)
        case let .array(contextA, contextB):
            return .array(contextA.with(title: title), contextB)
        case let .number(context, contextB):
            return .number(context.with(title: title), contextB)
        case let .integer(context, contextB):
            return .integer(context.with(title: title), contextB)
        case let .string(context, contextB):
            return .string(context.with(title: title), contextB)
        case let .fragment(context):
            return .fragment(context.with(title: title))
        case let .all(of: fragments, core: core):
            return .all(of: fragments, core: core.with(title: title))
        case let .one(of: schemas, core: core):
            return .one(of: schemas, core: core.with(title: title))
        case let .any(of: schemas, core: core):
            return .any(of: schemas, core: core.with(title: title))
        case let .not(schema, core: core):
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
