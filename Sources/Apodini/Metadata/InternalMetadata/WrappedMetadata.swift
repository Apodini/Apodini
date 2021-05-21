//
// Created by Andreas Bauer on 21.05.21.
//

struct WrappedHandlerMetadataDeclaration<Metadata: HandlerMetadataDeclaration>: AnyHandlerMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedComponentOnlyMetadataDeclaration<Metadata: ComponentOnlyMetadataDeclaration>: AnyComponentOnlyMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedWebServiceMetadataDeclaration<Metadata: WebServiceMetadataDeclaration>: AnyWebServiceMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedComponentMetadataDeclaration<Metadata: ComponentMetadataDeclaration>: AnyComponentMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}

struct WrappedContentMetadataDeclaration<Metadata: ContentMetadataDeclaration>: AnyContentMetadata {
    let metadata: Metadata

    init(_ metadata: Metadata) {
        self.metadata = metadata
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        metadata.accept(visitor)
    }
}
