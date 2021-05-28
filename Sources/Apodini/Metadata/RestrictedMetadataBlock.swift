//
// Created by Andreas Bauer on 21.05.21.
//

/// A `RestrictedMetadataBlock` is a  `AnyMetadataBlock` which is restricted to only contain
/// a specific Type of `AnyMetadata` (`RestrictedMetadataBlock`s support arbitrary nesting, meaning
/// they always can contain themselves).
///
/// In order to support multiple `AnyMetadata` which is allowed inside a `RestrictedMetadataBlock`,
/// use a class as the base Metadata type, creating subclasses for all allowed Metadata.
///
/// The following `RestrictedMetadataBlock`s are supported, depending on what `AnyMetadata` they support
/// and in which Declaration Blocks they can be placed:
/// - `RestrictedHandlerMetadataBlock`
/// - `RestrictedComponentOnlyMetadataBlock`
/// - `RestrictedWebServiceMetadataBlock`
/// - `RestrictedComponentMetadataBlock`
/// - `RestrictedContentMetadataBlock`
public protocol RestrictedMetadataBlock: AnyMetadataBlock {
    associatedtype RestrictedContent: AnyMetadata
}

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

    public var content: AnyHandlerMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> content: () -> AnyHandlerMetadata) {
        self.content = content()
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

    public var content: AnyComponentOnlyMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> content: () -> AnyComponentOnlyMetadata) {
        self.content = content()
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

    public var content: AnyWebServiceMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> content: () -> AnyWebServiceMetadata) {
        self.content = content()
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

    public var content: AnyComponentMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> content: () -> AnyComponentMetadata) {
        self.content = content()
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

    public var content: AnyContentMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> content: () -> AnyContentMetadata) {
        self.content = content()
    }
}
