//
// Created by Andreas Bauer on 21.05.21.
//

public struct ComponentMetadataModifier<C: Component>: Modifier {
    public let component: C
    // property is not called `metadata` as it would conflict with the Metadata Declaration block
    let componentMetadata: AnyComponentOnlyMetadata

    public init<Metadata: ComponentOnlyMetadataDefinition>(modifies component: C, with metadata: Metadata) {
        self.component = component
        self.componentMetadata = metadata
    }

    fileprivate init(modifies component: C, with metadata: AnyComponentOnlyMetadata) {
        self.component = component
        self.componentMetadata = metadata
    }
}

extension ComponentMetadataModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        component.accept(visitor)
        // Modifier has precedence over any Metadata defined in the Component itself  (executed afterwards)
        componentMetadata.accept(visitor)
    }
}

extension Component {
    /// The `Component.metadata(content:)` Modifier can be used to apply a Component Metadata Declaration Block
    /// to the given `Component`.
    /// - Parameter content: The closure containing the Metadata to be built.
    /// - Returns: The modified `Component` with the added Metadata.
    public func metadata(@MetadataBuilder content: () -> AnyComponentOnlyMetadata) -> ComponentMetadataModifier<Self> {
        ComponentMetadataModifier(modifies: self, with: content())
    }

    /// The `Component.metadata(...)` Modifier can be used to add a instance of a `AnyComponentOnlyMetadata` Metadata
    /// to the given `Component`.
    /// - Parameter metadata: The instance of `AnyComponentOnlyMetadata`.
    /// - Returns: The modified `Component` with the added Metadata.
    public func metadata<Metadata: AnyComponentOnlyMetadata>(_ metadata: Metadata) -> ComponentMetadataModifier<Self> {
        ComponentMetadataModifier(modifies: self, with: metadata)
    }
}
