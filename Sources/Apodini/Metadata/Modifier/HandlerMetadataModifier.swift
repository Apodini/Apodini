//
// Created by Andreas Bauer on 21.05.21.
//

/// The `HandlerMetadataModifier` can be used to easily add `HandlerMetadataDefinition`
/// to a `Handler` via a `HandlerModifier`.
/// Apodini provides `Handler.metadata(content:)` and `Handler.metadata(...)` as general purpose
/// Modifiers to add arbitrary Metadata to a `Handler`.
///
/// Furthermore `HandlerMetadataModifier` serves as a build block to easily create a custom
/// `HandlerModifier` for your `HandlerMetadataDefinition` without much overhead.
/// In order to create a Modifier declare a `Handler` extension as usual, returning a
/// `HandlerMetadataModifier` instantiated via `HandlerMetadataModifier.init(modifies:with:)`:
/// ```swift
/// extension Handler {
///     public func myModifier(_ value: ExampleValue) -> HandlerMetadataModifier<Self> {
///         HandlerMetadataModifier(modifies: self, with: ExampleHandlerMetadata(value))
///     }
/// }
/// ```
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
    ///
    /// - Note: Be aware that `Handler`s and therefore `HandlerModifier` are declared inside `Component`s,
    ///     thus the `HandlerMetadataNamespace` is not available there and only `MetadataDefinition`s
    ///     from `ComponentMetadataNamespace` are available.
    ///     As a workaround declare your `AnyHandlerMetadata` in a separate `HandlerMetadataBlock` and use it here.
    public func metadata(@MetadataBuilder content: () -> AnyHandlerMetadata) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: content())
    }

    /// The `Handler.metadata(...)` Modifier can be used to add a instance of a `AnyHandlerMetadata` Metadata
    /// to the given `Handler`.
    /// - Parameter metadata: The instance of `AnyHandlerMetadata`.
    /// - Returns: The modified `Handler` with the added Metadata.
    ///
    /// - Note: Be aware that `Handler`s and therefore `HandlerModifier` are declared inside `Component`s,
    ///     thus the `HandlerMetadataNamespace` is not available there and only `MetadataDefinition`s
    ///     from `ComponentMetadataNamespace` are available.
    ///     As a workaround declare your `AnyHandlerMetadata` in a separate `HandlerMetadataBlock` and use it here.
    public func metadata<Metadata: AnyHandlerMetadata>(_ metadata: Metadata) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: metadata)
    }
}
