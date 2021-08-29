//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import OpenAPIKit

extension JSONSchema {
    /// Ensures that the root `JSONSchema` is not a JSONReference.
    /// If it is a reference, the method does a single lookup, dereferencing the root schema, returning
    /// a json schema which might still contain transitive references.
    func rootDereference(in components: OpenAPIKit.OpenAPI.Components) throws -> JSONSchema {
        switch self {
        case let .reference(reference):
            return try components.lookup(reference)
        default:
            return self
        }
    }
}
