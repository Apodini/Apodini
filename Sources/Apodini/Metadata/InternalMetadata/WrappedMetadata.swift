//
// Created by Andreas Bauer on 21.05.21.
//

struct WrappedHandlerMetadataDefinition<Metadata: HandlerMetadataDefinition>: AnyHandlerMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedComponentOnlyMetadataDefinition<Metadata: ComponentOnlyMetadataDefinition>: AnyComponentOnlyMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedWebServiceMetadataDefinition<Metadata: WebServiceMetadataDefinition>: AnyWebServiceMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedComponentMetadataDefinition<Metadata: ComponentMetadataDefinition>: AnyComponentMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedContentMetadataDefinition<Metadata: ContentMetadataDefinition>: AnyContentMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}
