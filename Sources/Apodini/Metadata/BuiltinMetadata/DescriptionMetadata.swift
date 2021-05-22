//
// Created by Andreas Bauer on 17.05.21.
//

public struct DescriptionContextKey: OptionalContextKey {
    public typealias Value = String
}

// As ContentMetadata currently still shares the `Context` with the Handler
// we need to declare a custom `OptionalContextKey` to avoid collisions.
public struct ContentDescriptionContextKey: OptionalContextKey {
    public typealias Value = String
}

extension ComponentMetadataNamespace {
    /// Name Definition for the `ComponentDescriptionMetadata`
    public typealias Description = ComponentDescriptionMetadata
}

extension ContentMetadataNamespace {
    /// Name Definition for the `ContentDescriptionMetadata`
    public typealias Description = ContentDescriptionMetadata
}

/// The `ComponentDescriptionMetadata` can be used to add a Description to a `Component`.
/// The Metadata is available under the `Description` name and can be used like the following:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         Description("Example Description")
///     }
/// }
/// ```
public struct ComponentDescriptionMetadata: ComponentMetadataDefinition {
    public typealias Key = DescriptionContextKey
    public let value: String

    /// Creates a new Description Metadata
    /// - Parameter description: The description for the Component.
    public init(_ description: String) {
        self.value = description
    }
}

/// The `ContentDescriptionMetadata` can be used to add a Description to a `Content`.
/// The Metadata is available under the `Description` name and can be used like the following:
/// ```swift
/// struct ExampleContent: Content {
///     // ...
///     var metadata: Metadata {
///         Description("Example Description")
///     }
/// }
/// ```
public struct ContentDescriptionMetadata: ContentMetadataDefinition {
    public typealias Key = ContentDescriptionContextKey
    public let value: String

    /// Creates a new Description Metadata.
    /// - Parameter description: The description for the Content Type.
    public init(_ description: String) {
        self.value = description
    }
}


extension Component {
    /// A `description` Modifier can be used to specify the `ComponentDescriptionMetadata` via a `Modifier`.
    /// - Parameter description: The description used for the `Component`.
    /// - Returns: The modified `Component` with the `ComponentDescriptionMetadata` added.
    public func description(_ description: String) -> ComponentMetadataModifier<Self> {
        ComponentMetadataModifier(modifies: self, with: ComponentDescriptionMetadata(description))
    }
}

extension Handler {
    /// A `description` Modifier can be used to specify the `ComponentDescriptionMetadata` via a `HandlerModifier`.
    /// - Parameter description: The `description` that is used to for the `Handler`.
    /// - Returns: The modified `Handler` with the `ComponentDescriptionMetadata` added.
    public func description(_ value: String) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: ComponentDescriptionMetadata(value))
    }
}
