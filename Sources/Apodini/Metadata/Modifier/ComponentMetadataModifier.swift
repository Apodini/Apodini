//
// Created by Andreas Bauer on 21.05.21.
//

public struct ComponentMetadataModifier<C: Component, Metadata: ComponentOnlyMetadataDefinition>: Modifier {
    public let component: C
    // property is not called `metadata` as it would conflict with the Metadata Declaration block
    let componentMetadata: Metadata

    public init(modifies component: C, with metadata: Metadata) {
        self.component = component
        self.componentMetadata = metadata
    }
}

extension ComponentMetadataModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        componentMetadata.accept(visitor)
        component.accept(visitor)
    }
}
