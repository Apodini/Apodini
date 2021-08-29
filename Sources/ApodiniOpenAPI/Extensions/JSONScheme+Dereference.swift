//
// Created by Andreas Bauer on 29.08.21.
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
