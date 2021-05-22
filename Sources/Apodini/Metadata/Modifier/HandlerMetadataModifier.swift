//
// Created by Andreas Bauer on 21.05.21.
//

public struct HandlerMetadataModifier<H: Handler>: HandlerModifier {
    public let component: H
    // property is not called `metadata` as it would conflict with the Metadata Declaration block
    let handlerMetadata: AnyHandlerMetadata

    init<Metadata: HandlerMetadataDefinition>(modifies handler: H, with metadata: Metadata) {
        self.component = handler
        self.handlerMetadata = metadata
    }

    fileprivate init(modifies handler: H, with metadata: AnyHandlerMetadata) {
        self.component = handler
        self.handlerMetadata = metadata
    }
}

extension HandlerMetadataModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        handlerMetadata.accept(visitor)
        component.accept(visitor)
    }
}

extension Handler {
    /// The `Handler.metadata(content:)` Modifier can be used to apply a Handler Metadata Declaration Block
    /// to the given `Handler`.
    /// - Parameter content: The closure containing the Metadata to be built.
    /// - Returns: The modified `Handler` with the added Metadata.
    public func metadata(@MetadataBuilder content: () -> AnyHandlerMetadata) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: content())
    }

    /// The `Handler.metadata(...)` Modifier can be used to add a instance of a `AnyHandlerMetadata` Metadata
    /// to the given `Handler`.
    /// - Parameter metadata: The instance of `AnyHandlerMetadata`.
    /// - Returns: The modified `Handler` with the added Metadata.
    public func metadata<Metadata: AnyHandlerMetadata>(_ metadata: Metadata) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: metadata)
    }
}
