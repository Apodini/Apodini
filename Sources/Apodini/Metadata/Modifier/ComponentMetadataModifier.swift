//
// Created by Andreas Bauer on 21.05.21.
//

/// The `ComponentMetadataModifier` can be used to easily add `ComponentMetadataDefinition`
/// to a `Component` via a `Modifier`.
/// Apodini provides `Component.metadata(content:)` and `Component.metadata(...)` as general purpose
/// Modifiers to add arbitrary Metadata to a `Component`.
///
/// Furthermore `ComponentMetadataModifier` serves as a build block to easily create a custom
/// `Modifier` for your `ComponentMetadataDefinition` without much overhead.
/// In order to create a Modifier declare a `Component` extension as usual, returning a
/// `ComponentMetadataModifier` instantiated via `ComponentMetadataModifier.init(modifies:with:)`:
/// ```swift
/// extension Component {
///     public func myModifier(_ value: ExampleValue) -> ComponentMetadataModifier<Self> {
///         ComponentMetadataModifier(modifies: self, with: ExampleComponentMetadata(value))
///     }
/// }
/// ```
///
/// - Note: Be aware that a `Modifier` can be applied to all `Component`s including `Handler` and `WebService`.
/// Therefore it is advised to not use `ComponentOnlyMetadataDefinition` with `ComponentMetadataModifier`.
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
        componentMetadata.accept(visitor)
        component.accept(visitor)
    }
}

extension ComponentMetadataModifier: HandlerModifier where Self.ModifiedComponent: Handler {
    public typealias Response = ModifiedComponent.Response
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
