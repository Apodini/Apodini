//
// Created by Andreas Bauer on 21.05.21.
//

// TODO docs: RestrictedContent generic can only ever be one specific AnyMetadata instance;
//   if you want to allow more than one, use a class and subclass from it
public protocol RestrictedMetadataGroup: AnyMetadataGroup {
    associatedtype RestrictedContent: AnyMetadata
}

public struct RestrictedHandlerMetadataGroup<RestrictedContent: AnyHandlerMetadata>: HandlerMetadataGroup, RestrictedMetadataGroup {
    public typealias RestrictedContent = RestrictedContent

    public var content: AnyHandlerMetadata

    public init(@RestrictedMetadataGroupBuilder<Self> content: () -> AnyHandlerMetadata) {
        self.content = content()
    }
}

public struct RestrictedComponentOnlyMetadataGroup<RestrictedContent: AnyComponentOnlyMetadata>: ComponentOnlyMetadataGroup, RestrictedMetadataGroup {
    public typealias RestrictedContent = RestrictedContent

    public var content: AnyComponentOnlyMetadata

    public init(@RestrictedMetadataGroupBuilder<Self> content: () -> AnyComponentOnlyMetadata) {
        self.content = content()
    }
}

public struct RestrictedWebServiceMetadataGroup<RestrictedContent: AnyWebServiceMetadata>: WebServiceMetadataGroup, RestrictedMetadataGroup {
    public typealias RestrictedContent = RestrictedContent

    public var content: AnyWebServiceMetadata

    public init(@RestrictedMetadataGroupBuilder<Self> content: () -> AnyWebServiceMetadata) {
        self.content = content()
    }
}

public struct RestrictedComponentMetadataGroup<RestrictedContent: AnyComponentMetadata>: ComponentMetadataGroup, RestrictedMetadataGroup {
    public typealias RestrictedContent = RestrictedContent

    public var content: AnyComponentMetadata

    public init(@RestrictedMetadataGroupBuilder<Self> content: () -> AnyComponentMetadata) {
        self.content = content()
    }
}

public struct RestrictedContentMetadataGroup<RestrictedContent: AnyContentMetadata>: ContentMetadataGroup, RestrictedMetadataGroup {
    public typealias RestrictedContent = RestrictedContent

    public var content: AnyContentMetadata

    public init(@RestrictedMetadataGroupBuilder<Self> content: () -> AnyContentMetadata) {
        self.content = content()
    }
}
