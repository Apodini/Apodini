//
// Created by Andreas Bauer on 17.05.21.
//

public struct DescriptionContextKey: OptionalContextKey {
    public typealias Value = String
}

public extension ComponentMetadataNamespace {
    typealias Description = ComponentDescriptionMetadata
}

public extension ContentMetadataNamespace {
    typealias Description = ContentDescriptionMetadata
}

public struct ComponentDescriptionMetadata: ComponentMetadataDefinition {
    public typealias Key = DescriptionContextKey

    public let value: String

    public init(_ description: String) {
        self.value = description
    }
}

extension Component {
    public func description(_ value: String) -> ComponentMetadataModifier<Self, ComponentDescriptionMetadata> {
        ComponentMetadataModifier(modifies: self, with: ComponentDescriptionMetadata(value))
    }
}

extension Handler {
    /// A `description` modifier can be used to explicitly specify the `description` for the given `Handler`
    /// - Parameter description: The `description` that is used to for the handler
    /// - Returns: The modified `Handler` with a specified `description`
    /// TODO maybe some words about Metadata relation?
    public func description(_ value: String) -> HandlerMetadataModifier<Self, ComponentDescriptionMetadata> {
        HandlerMetadataModifier(modifies: self, with: ComponentDescriptionMetadata(value))
    }
}
