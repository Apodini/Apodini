//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        componentMetadata.accept(visitor)
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
