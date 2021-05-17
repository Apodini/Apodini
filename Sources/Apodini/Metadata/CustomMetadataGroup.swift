//
// Created by Andreas Bauer on 17.05.21.
//

import Foundation

// TODO is "Custom" the right naming prefix?

// TODO document all available Metadata Groups
public protocol CustomMetadataGroup: MetadataGroup {
    // This protocol is only present to provide a centralized documentation
    // to the outside for custom metadata groups
}

protocol _CustomMetadataGroup: CustomMetadataGroup {
    init(wrappedContent: AnyMetadata)
}

extension CustomMetadataGroup {
    static func toInternalType() -> _CustomMetadataGroup.Type {
        guard let group = Self.self as? _CustomMetadataGroup.Type else {
            fatalError("Encountered `CustomMetadataGroup` which doesn't conform to `_CustomMetadataGroup`: \(self)!")
        }
        return group
    }
}

public struct CustomWebServiceMetadataGroup<Content: WebServiceMetadata>: _CustomMetadataGroup, WebServiceMetadata {
    public var content: AnyMetadata

    init(wrappedContent: AnyMetadata) {
        self.content = wrappedContent
    }

    public init(@CustomMetadataGroupBuilder<Self, Content> content: () -> AnyMetadata) {
        self.content = content()
    }
}

public struct CustomHandlerMetadataGroup<Content: HandlerMetadata>: _CustomMetadataGroup, HandlerMetadata {
    public var content: AnyMetadata

    init(wrappedContent: AnyMetadata) {
        self.content = wrappedContent
    }

    public init(@CustomMetadataGroupBuilder<Self, Content> content: () -> AnyMetadata) {
        self.content = content()
    }
}

public struct CustomComponentOnlyMetadataGroup<Content: ComponentOnlyMetadata>: _CustomMetadataGroup, ComponentOnlyMetadata {
    public var content: AnyMetadata

    init(wrappedContent: AnyMetadata) {
        self.content = wrappedContent
        // TODO somehow assert that content is really only ComponenetMetadataGroup<Content> or Content
    }

    public init(@CustomMetadataGroupBuilder<Self, Content> content: () -> AnyMetadata) {
        self.content = content()
    }
}

public struct CustomComponentMetadataGroup<Content: ComponentMetadata>: _CustomMetadataGroup, ComponentMetadata {
    public var content: AnyMetadata

    init(wrappedContent: AnyMetadata) {
        self.content = wrappedContent
        // TODO somehow assert that content is really only ComponenetMetadataGroup<Content> or Content
    }

    public init(@CustomMetadataGroupBuilder<Self, Content> content: () -> AnyMetadata) {
        self.content = content()
    }
}

public struct CustomContentMetadataGroup<Content: ContentMetadata>: _CustomMetadataGroup, ContentMetadata {
    public var content: AnyMetadata

    init(wrappedContent: AnyMetadata) {
        self.content = wrappedContent
        // TODO somehow assert that content is really only ComponenetMetadataGroup<Content> or Content
    }

    public init(@CustomMetadataGroupBuilder<Self, Content> content: () -> AnyMetadata) {
        self.content = content()
    }
}
