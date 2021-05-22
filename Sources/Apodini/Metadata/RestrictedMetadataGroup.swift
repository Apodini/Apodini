//
// Created by Andreas Bauer on 21.05.21.
//

/// A `RestrictedMetadataGroup` is a  `AnyMetadataGroup` which is restricted to only contain
/// a specific Type of `AnyMetadata` (`RestrictedMetadataGroup`s support arbitrary nesting, meaning
/// they always can contain themselves).
///
/// In order to support multiple `AnyMetadata` which is allowed inside a `RestrictedMetadataGroup`,
/// use a class as the base Metadata type, creating subclasses for all allowed Metadata.
///
/// The following `RestrictedMetadataGroup`s are supported, depending on what `AnyMetadata` they support
/// and in which Declaration Blocks they can be placed:
/// - `RestrictedHandlerMetadataGroup`
/// - `RestrictedComponentOnlyMetadataGroup`
/// - `RestrictedWebServiceMetadataGroup`
/// - `RestrictedComponentMetadataGroup`
/// - `RestrictedContentMetadataGroup`
public protocol RestrictedMetadataGroup: AnyMetadataGroup {
    associatedtype RestrictedContent: AnyMetadata
}

/// The `RestrictedHandlerMetadataGroup` protocol represents `RestrictedMetadataGroup`s which can only contain
/// `AnyHandlerMetadata` and itself can only be placed in `AnyHandlerMetadata` Declaration Blocks.
/// Use the generic type `RestrictedContent` to define which `AnyHandlerMetadata` is allowed in the group.
///
/// Given a `Example` Metadata (already part of the `HandlerMetadataNamespace`), a `RestrictedHandlerMetadataGroup`
/// can be added to the Namespace like the following:
/// ```swift
/// extension HandlerMetadataNamespace {
///     public typealias Examples = RestrictedHandlerMetadataGroup<Example>
/// }
/// ```
public struct RestrictedHandlerMetadataGroup<RestrictedContent: AnyHandlerMetadata>: HandlerMetadataGroup, RestrictedMetadataGroup {
    public typealias RestrictedContent = RestrictedContent

    public var content: AnyHandlerMetadata

    public init(@RestrictedMetadataGroupBuilder<Self> content: () -> AnyHandlerMetadata) {
        self.content = content()
    }
}

/// The `RestrictedComponentOnlyMetadataGroup` protocol represents `RestrictedMetadataGroup`s which can only contain
/// `AnyComponentOnlyMetadata` and itself can only be placed in `AnyComponentOnlyMetadata` Declaration Blocks.
/// Use the generic type `RestrictedContent` to define which `AnyComponentOnlyMetadata` is allowed in the group.
///
/// Given a `Example` Metadata (already part of the `ComponentMetadataNamespace`), a `RestrictedComponentOnlyMetadataGroup`
/// can be added to the Namespace like the following:
/// ```swift
/// extension ComponentMetadataNamespace {
///     public typealias Examples = RestrictedComponentOnlyMetadataGroup<Example>
/// }
/// ```
///
/// - Note: See Note of `ComponentOnlyMetadataDefinition` regarding a missing dedicated Component-Only Namespace.
public struct RestrictedComponentOnlyMetadataGroup<RestrictedContent: AnyComponentOnlyMetadata>: ComponentOnlyMetadataGroup, RestrictedMetadataGroup {
    public typealias RestrictedContent = RestrictedContent

    public var content: AnyComponentOnlyMetadata

    public init(@RestrictedMetadataGroupBuilder<Self> content: () -> AnyComponentOnlyMetadata) {
        self.content = content()
    }
}

/// The `RestrictedWebServiceMetadataGroup` protocol represents `RestrictedMetadataGroup`s which can only contain
/// `AnyWebServiceMetadata` and itself can only be placed in `AnyWebServiceMetadata` Declaration Blocks.
/// Use the generic type `RestrictedContent` to define which `AnyWebServiceMetadata` is allowed in the group.
///
/// Given a `Example` Metadata (already part of the `WebServiceMetadataNamespace`), a `RestrictedWebServiceMetadataGroup`
/// can be added to the Namespace like the following:
/// ```swift
/// extension WebServiceMetadataNamespace {
///     public typealias Examples = RestrictedWebServiceMetadataGroup<Example>
/// }
/// ```
public struct RestrictedWebServiceMetadataGroup<RestrictedContent: AnyWebServiceMetadata>: WebServiceMetadataGroup, RestrictedMetadataGroup {
    public typealias RestrictedContent = RestrictedContent

    public var content: AnyWebServiceMetadata

    public init(@RestrictedMetadataGroupBuilder<Self> content: () -> AnyWebServiceMetadata) {
        self.content = content()
    }
}

/// The `RestrictedComponentMetadataGroup` protocol represents `RestrictedMetadataGroup`s which can only contain
/// `AnyComponentMetadata` and itself can only be placed in `AnyComponentMetadata` Declaration Blocks.
/// Use the generic type `RestrictedContent` to define which `AnyComponentMetadata` is allowed in the group.
///
/// Given a `Example` Metadata (already part of the `ComponentMetadataNamespace`), a `RestrictedComponentMetadataGroup`
/// can be added to the Namespace like the following:
/// ```swift
/// extension ComponentMetadataNamespace {
///     public typealias Examples = RestrictedComponentMetadataGroup<Example>
/// }
/// ```
public struct RestrictedComponentMetadataGroup<RestrictedContent: AnyComponentMetadata>: ComponentMetadataGroup, RestrictedMetadataGroup {
    public typealias RestrictedContent = RestrictedContent

    public var content: AnyComponentMetadata

    public init(@RestrictedMetadataGroupBuilder<Self> content: () -> AnyComponentMetadata) {
        self.content = content()
    }
}

/// The `RestrictedContentMetadataGroup` protocol represents `RestrictedMetadataGroup`s which can only contain
/// `AnyContentMetadata` and itself can only be placed in `AnyContentMetadata` Declaration Blocks.
/// Use the generic type `RestrictedContent` to define which `AnyContentMetadata` is allowed in the group.
///
/// Given a `Example` Metadata (already part of the `ContentMetadataNamespace`), a `RestrictedContentMetadataGroup`
/// can be added to the Namespace like the following:
/// ```swift
/// extension ContentMetadataNamespace {
///     public typealias Examples = RestrictedContentMetadataGroup<Example>
/// }
/// ```
public struct RestrictedContentMetadataGroup<RestrictedContent: AnyContentMetadata>: ContentMetadataGroup, RestrictedMetadataGroup {
    public typealias RestrictedContent = RestrictedContent

    public var content: AnyContentMetadata

    public init(@RestrictedMetadataGroupBuilder<Self> content: () -> AnyContentMetadata) {
        self.content = content()
    }
}
