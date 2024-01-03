//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
    public typealias MetadataBuilderScope = C.MetadataBuilderScope
    public let component: C
    // property is not called `metadata` as it would conflict with the Metadata Declaration block
    let componentMetadata: any AnyComponentOnlyMetadata

    public init<Metadata: ComponentOnlyMetadataDefinition>(modifies component: C, with metadata: Metadata) {
        self.component = component
        self.componentMetadata = metadata
    }

    fileprivate init(modifies component: C, with metadata: any AnyComponentOnlyMetadata) {
        self.component = component
        self.componentMetadata = metadata
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        componentMetadata.collectMetadata(visitor)
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
    public func metadata(
        @MetadataBuilder<MetadataBuilderScope> content: () -> any AnyComponentOnlyMetadata
    ) -> ComponentMetadataModifier<Self> where MetadataBuilderScope == MetadataBuilderScope_ComponentOnly {
        ComponentMetadataModifier(modifies: self, with: content())
    }
    
    /// The `Component.metadata(...)` Modifier can be used to add a instance of a `AnyComponentOnlyMetadata` Metadata
    /// to the given `Component`.
    /// - Parameter metadata: The instance of `AnyComponentOnlyMetadata`.
    /// - Returns: The modified `Component` with the added Metadata.
    public func metadata<Metadata: AnyComponentOnlyMetadata>(
        _ metadata: Metadata
    ) -> ComponentMetadataModifier<Self> where MetadataBuilderScope == MetadataBuilderScope_ComponentOnly {
        ComponentMetadataModifier(modifies: self, with: metadata)
    }
    
    
    
    // TODO UPDATE DOCS HERE!!!
    /// The `Component.metadata(content:)` Modifier can be used to apply a Component Metadata Declaration Block
    /// to the given `Component`.
    /// - Parameter content: The closure containing the Metadata to be built.
    /// - Returns: The modified `Component` with the added Metadata.
    public func metadata(
        @MetadataBuilder<MetadataBuilderScope> content: () -> any AnyComponentMetadata
    ) -> ComponentMetadataModifier<Self> {
        ComponentMetadataModifier(modifies: self, with: content())
    }
    
    // TODO UPDATE DOCS HERE!!!
    /// The `Component.metadata(...)` Modifier can be used to add a instance of a `AnyComponentOnlyMetadata` Metadata
    /// to the given `Component`.
    /// - Parameter metadata: The instance of `AnyComponentOnlyMetadata`.
    /// - Returns: The modified `Component` with the added Metadata.
    @_disfavoredOverload // TODO is this actually needed?
    public func metadata<Metadata: AnyComponentMetadata>(
        _ metadata: Metadata
    ) -> ComponentMetadataModifier<Self> {
        ComponentMetadataModifier(modifies: self, with: metadata)
    }
}
