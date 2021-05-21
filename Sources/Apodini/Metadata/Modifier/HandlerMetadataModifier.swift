//
// Created by Andreas Bauer on 21.05.21.
//

public struct HandlerMetadataModifier<H: Handler, Metadata: HandlerMetadataDefinition>: HandlerModifier {
    public let component: H
    // property is not called `metadata` as it would conflict with the Metadata Declaration block
    let handlerMetadata: Metadata

    init(modifies handler: H, with metadata: Metadata) {
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
