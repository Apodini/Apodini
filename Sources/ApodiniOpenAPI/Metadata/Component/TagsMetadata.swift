//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public struct TagContextKey: OptionalContextKey {
    public typealias Value = [String]
}

public extension ComponentMetadataNamespace {
    /// Name definition for the ``TagsMetadata``.
    typealias Tags = TagsMetadata
}

/// The ``TagsMetadata`` can be used to define OpenAPI tags for a `Component`.
///
/// The Metadata is available under the `ComponentMetadataNamespace/Tags` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         Tags("authentication", "example")
///     }
/// }
/// ```
public struct TagsMetadata: ComponentMetadataDefinition {
    public typealias Key = TagContextKey

    public let value: [String]

    public init(_ tags: [String]) {
        self.value = tags
    }

    public init(_ tags: String...) {
        self.init(tags)
    }
}

extension Component {
    /// A `tag` modifier can be used to explicitly specify the `tags` for the given `Handler`
    /// - Parameter tags: Arbitrary amount of `tags` that are used for logical grouping of operations, e.g., within the API documentation
    /// - Returns: The modified `Handler` with specific `tags`
    public func tags(_ tags: [String]) -> ComponentMetadataModifier<Self> {
        metadata(TagsMetadata(tags))
    }

    /// A `tag` modifier can be used to explicitly specify the `tags` for the given `Handler`
    /// - Parameter tags: Arbitrary amount of `tags` that are used for logical grouping of operations, e.g., within the API documentation
    /// - Returns: The modified `Handler` with specific `tags`
    public func tags(_ tags: String...) -> ComponentMetadataModifier<Self> {
        self.tags(tags)
    }
}

extension Handler {
    /// A `tag` modifier can be used to explicitly specify the `tags` for the given `Handler`
    /// - Parameter tags: Arbitrary amount of `tags` that are used for logical grouping of operations, e.g., within the API documentation
    /// - Returns: The modified `Handler` with specific `tags`
    public func tags(_ tags: [String]) -> HandlerMetadataModifier<Self> {
        metadata(TagsMetadata(tags))
    }

    /// A `tag` modifier can be used to explicitly specify the `tags` for the given `Handler`
    /// - Parameter tags: Arbitrary amount of `tags` that are used for logical grouping of operations, e.g., within the API documentation
    /// - Returns: The modified `Handler` with specific `tags`
    public func tags(_ tags: String...) -> HandlerMetadataModifier<Self> {
        self.tags(tags)
    }
}
