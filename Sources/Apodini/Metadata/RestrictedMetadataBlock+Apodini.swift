//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem


/// The `RestrictedHandlerMetadataBlock` protocol represents `RestrictedMetadataBlock`s which can only contain
/// `AnyHandlerMetadata` and itself can only be placed in `AnyHandlerMetadata` Declaration Blocks.
/// Use the generic type `RestrictedContent` to define which `AnyHandlerMetadata` is allowed in the Block.
///
/// Given a `Example` Metadata (already part of the `HandlerMetadataNamespace`), a `RestrictedHandlerMetadataBlock`
/// can be added to the Namespace like the following:
/// ```swift
/// extension HandlerMetadataNamespace {
///     public typealias Examples = RestrictedHandlerMetadataBlock<Example>
/// }
/// ```
public struct RestrictedHandlerMetadataBlock<RestrictedContent: AnyHandlerMetadata>: HandlerMetadataBlock, RestrictedMetadataBlock {
    public typealias RestrictedContent = RestrictedContent

    public var metadata: AnyHandlerMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> metadata: () -> AnyHandlerMetadata) {
        self.metadata = metadata()
    }
}

/// The `RestrictedComponentOnlyMetadataBlock` protocol represents `RestrictedMetadataBlock`s which can only contain
/// `AnyComponentOnlyMetadata` and itself can only be placed in `AnyComponentOnlyMetadata` Declaration Blocks.
/// Use the generic type `RestrictedContent` to define which `AnyComponentOnlyMetadata` is allowed in the Block.
///
/// Given a `Example` Metadata (already part of the `ComponentMetadataNamespace`), a `RestrictedComponentOnlyMetadataBlock`
/// can be added to the Namespace like the following:
/// ```swift
/// extension ComponentMetadataNamespace {
///     public typealias Examples = RestrictedComponentOnlyMetadataBlock<Example>
/// }
/// ```
///
/// - Note: See Note of `ComponentOnlyMetadataDefinition` regarding a missing dedicated Component-Only Namespace.
public struct RestrictedComponentOnlyMetadataBlock<RestrictedContent: AnyComponentOnlyMetadata>: ComponentOnlyMetadataBlock, RestrictedMetadataBlock {
    public typealias RestrictedContent = RestrictedContent

    public var metadata: AnyComponentOnlyMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> metadata: () -> AnyComponentOnlyMetadata) {
        self.metadata = metadata()
    }
}

/// The `RestrictedWebServiceMetadataBlock` protocol represents `RestrictedMetadataBlock`s which can only contain
/// `AnyWebServiceMetadata` and itself can only be placed in `AnyWebServiceMetadata` Declaration Blocks.
/// Use the generic type `RestrictedContent` to define which `AnyWebServiceMetadata` is allowed in the Block.
///
/// Given a `Example` Metadata (already part of the `WebServiceMetadataNamespace`), a `RestrictedWebServiceMetadataBlock`
/// can be added to the Namespace like the following:
/// ```swift
/// extension WebServiceMetadataNamespace {
///     public typealias Examples = RestrictedWebServiceMetadataBlock<Example>
/// }
/// ```
public struct RestrictedWebServiceMetadataBlock<RestrictedContent: AnyWebServiceMetadata>: WebServiceMetadataBlock, RestrictedMetadataBlock {
    public typealias RestrictedContent = RestrictedContent

    public var metadata: AnyWebServiceMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> metadata: () -> AnyWebServiceMetadata) {
        self.metadata = metadata()
    }
}

/// The `RestrictedComponentMetadataBlock` protocol represents `RestrictedMetadataBlock`s which can only contain
/// `AnyComponentMetadata` and itself can only be placed in `AnyComponentMetadata` Declaration Blocks.
/// Use the generic type `RestrictedContent` to define which `AnyComponentMetadata` is allowed in the Block.
///
/// Given a `Example` Metadata (already part of the `ComponentMetadataNamespace`), a `RestrictedComponentMetadataBlock`
/// can be added to the Namespace like the following:
/// ```swift
/// extension ComponentMetadataNamespace {
///     public typealias Examples = RestrictedComponentMetadataBlock<Example>
/// }
/// ```
public struct RestrictedComponentMetadataBlock<RestrictedContent: AnyComponentMetadata>: ComponentMetadataBlock, RestrictedMetadataBlock {
    public typealias RestrictedContent = RestrictedContent

    public var metadata: AnyComponentMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> metadata: () -> AnyComponentMetadata) {
        self.metadata = metadata()
    }
}

/// The `RestrictedContentMetadataBlock` protocol represents `RestrictedMetadataBlock`s which can only contain
/// `AnyContentMetadata` and itself can only be placed in `AnyContentMetadata` Declaration Blocks.
/// Use the generic type `RestrictedContent` to define which `AnyContentMetadata` is allowed in the Block.
///
/// Given a `Example` Metadata (already part of the `ContentMetadataNamespace`), a `RestrictedContentMetadataBlock`
/// can be added to the Namespace like the following:
/// ```swift
/// extension ContentMetadataNamespace {
///     public typealias Examples = RestrictedContentMetadataBlock<Example>
/// }
/// ```
public struct RestrictedContentMetadataBlock<RestrictedContent: AnyContentMetadata>: ContentMetadataBlock, RestrictedMetadataBlock {
    public typealias RestrictedContent = RestrictedContent

    public var metadata: AnyContentMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> metadata: () -> AnyContentMetadata) {
        self.metadata = metadata()
    }
}
