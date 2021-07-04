//
// Created by Andreas Bauer on 21.05.21.
//

/// A `MetadataDefinition` represents a specific type of Metadata which can be declared
/// on appropriate locations, like in the Metadata Declaration blocks of a `Component`.
/// To create a `MetadataDefinition` use one of the following protocols, depending on where
/// you want your `MetadataDefinition` to be accessible:
/// - `HandlerMetadataDefinition`
/// - `ComponentOnlyMetadataDefinition`
/// - `WebServiceMetadataDefinition`
/// - `ComponentMetadataDefinition`
/// - `ContentMetadataDefinition`
///
/// - Note: When creating `MetadataDefinition`s it is advised to give them unique and precise names.
///     The Metadata DSL subsystem is designed in such a way, that the Type name itself will and should
///     not be the name used by the user in the Metadata DSL. Therefore there is no reason to keep the names short
///     or name them according to some "natural language flow". Ideally all such definitions should
///     have the "Metadata" suffix (maybe adding even the scope e.g. "XXXXHandlerMetadata").
///     The name used in the Metadata DSL (the one which should ideally reflect the "natural language flow")
///     can be defined by extending the appropriate Metadata Namespace: `ComponentMetadataNamespace`,
///     `HandlerMetadataNamespace`, `WebServiceMetadataNamespace` or `ContentMetadataNamespace`.
public protocol MetadataDefinition: AnyMetadata {
    /// Either a `OptionalContextKey` or `ContextKey` used to store and identify the Metadata.
    associatedtype Key: OptionalContextKey

    /// The value which is to be stored.
    var value: Key.Value { get }
    /// The `Scope` in which the value is stored.
    /// In most cases you should not need to provide a custom value for this property.
    /// Apodini provides strong defaults, `Scope.current` for most Metadata and
    /// `Scope.environment` for Component Metadata.
    static var scope: Scope { get }
}

public extension MetadataDefinition {
    /// The default `Scope` for all `MetadataDefinition`s is `Scope.current`.
    static var scope: Scope {
        .current
    }
}

// MARK: SyntaxTreeVisitor
public extension MetadataDefinition {
    /// Default implementation to add the encapsulated value to the current `Context`.
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(Key.self, value: value, scope: Self.scope)

        if let metadataWithDelegatingHandler = self as? AnyDefinitionWithDynamicDelegatingHandler {
            metadataWithDelegatingHandler.addInitializerContextValue(visitor)
        }
    }
}

/// See `MetadataDefinition` for an explanation on what a Metadata Definition is
/// and a recommendation for a naming convention.
///
/// Any Metadata Definition conforming to `HandlerMetadataDefinition` can be used in
/// the Metadata Declaration Blocks of a `Handler` to annotate the `Handler` with
/// the given Metadata.
///
/// Use the `HandlerMetadataNamespace` to define the name used in the Metadata DSL.
public protocol HandlerMetadataDefinition: MetadataDefinition, AnyHandlerMetadata {}

/// See `MetadataDefinition` for an explanation on what a Metadata Definition is
/// and a recommendation for a naming convention.
///
/// Any Metadata Definition conforming to `ComponentOnlyMetadataDefinition` can be used in
/// the Metadata Declaration Blocks of a `Component` to annotate a `Component` with
/// the given Metadata.
/// `ComponentOnlyMetadataDefinition` cannot be used in the Metadata Declaration Blocks
/// of a `Handler` or the `WebService`. To use a Metadata Definition in all three of
/// those use `ComponentMetadataDefinition`.
///
/// - Note: It is advised to use `ComponentOnlyMetadataDefinition` with care as it doesn't have its
///     own Metadata Namespace. The `ComponentMetadataNamespace` or `ComponentOnlyMetadataNamespace`
///     is still accessible withing `Handler`s and the `WebService`.
public protocol ComponentOnlyMetadataDefinition: MetadataDefinition, AnyComponentOnlyMetadata {}

/// See `MetadataDefinition` for an explanation on what a Metadata Definition is
/// and a recommendation for a naming convention.
///
/// Any Metadata Definition conforming to `WebServiceMetadataDefinition` can be used in
/// the Metadata Declaration Blocks of a `WebService` to annotate the `WebService` with
/// the given Metadata.
///
/// Use the `WebServiceMetadataNamespace` to define the name used in the Metadata DSL.
public protocol WebServiceMetadataDefinition: MetadataDefinition, AnyWebServiceMetadata {}

/// See `MetadataDefinition` for an explanation on what a Metadata Definition is
/// and a recommendation for a naming convention.
///
/// Any Metadata Definition conforming to `ComponentMetadataDefinition` can be used in
/// the Metadata Declaration Blocks of `Component`s to annotate the `Component` with
/// the given Metadata.
/// `ComponentMetadataDefinition`s can be used in the Declaration Blocks of a `Handler` and
/// the `WebService`, as both are `Component`s.
///
/// Use the `ComponentMetadataNamespace` to define the name used in the Metadata DSL.
public protocol ComponentMetadataDefinition: HandlerMetadataDefinition, ComponentOnlyMetadataDefinition,
    WebServiceMetadataDefinition, AnyComponentMetadata {}

/// See `MetadataDefinition` for an explanation on what a Metadata Definition is
/// and a recommendation for a naming convention.
///
/// Any Metadata Definition conforming to `ContentMetadataDefinition` can be used in
/// the Metadata Declaration Blocks of a `Content` Type to annotate the `Content` Type with
/// the given Metadata.
///
/// Use the `ContentMetadataNamespace` to define the name used in the Metadata DSL.
public protocol ContentMetadataDefinition: MetadataDefinition, AnyContentMetadata {}


public extension ComponentOnlyMetadataDefinition {
    /// By default, `ComponentOnlyMetadataDefinition` will apply to the `Component.Content` as well.
    static var scope: Scope {
        .environment
    }
}

public extension ComponentMetadataDefinition {
    /// By default, `ComponentOnlyMetadataDefinition` will apply to the `Component.Content` as well.
    static var scope: Scope {
        .environment
    }
}
