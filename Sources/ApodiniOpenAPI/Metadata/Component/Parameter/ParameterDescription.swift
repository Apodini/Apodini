//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

public struct ParameterDescriptionContextKey: ContextKey {
    public typealias Value = [UUID: String]
    public static var defaultValue: [UUID: String] = [:]

    public static func reduce(value: inout Value, nextValue: Value) {
        value.merge(nextValue) { _, new in
            new
        }
    }
}

public extension TypedComponentMetadataNamespace {
    /// Name definition for the ``ParameterDescriptionMetadata``.
    typealias ParameterDescription = ParameterDescriptionMetadata<Self>
}

public extension ComponentMetadataNamespace {
    /// Name definition for the ``ParameterDescriptionMetadata``.
    typealias ParameterDescription<Element: Component> = ParameterDescriptionMetadata<Element>
}

/// The ``ParameterDescriptionMetadata`` can be used to define a description for a `@Parameter` inside Component Metadata Blocks.
///
/// The Metadata is available under the `ComponentMetadataNamespace/ParameterDescription` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     @Parameter var id: String
///     // ...
///     var metadata: Metadata {
///         ParameterDescription(for: $id, "The identifier")
///     }
/// }
/// ```
public struct ParameterDescriptionMetadata<Element: Component>: ComponentMetadataDefinition {
    public typealias Key = ParameterDescriptionContextKey
    public let value: ParameterDescriptionContextKey.Value

    /// Initializes a new Parameter Description Metadata.
    /// - Parameters:
    ///   - parameter: The binding (project value) of the `@Parameter` declaration.
    ///   - description: The description for the Parameter.
    public init<Value>(for parameter: Binding<Value>, _ description: String) {
        guard let id = _Internal.getParameterId(ofBinding: parameter) else {
            preconditionFailure("Parameter Description can only be constructed from a Binding of a @Parameter!")
        }
        self.value = [
            id: description
        ]
    }
}
