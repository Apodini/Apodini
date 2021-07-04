//
// Created by Andreas Bauer on 02.07.21.
//

/// A type erased `DefinitionWithDelegatingHandler`.
public protocol AnyDefinitionWithDynamicDelegatingHandler {
    /// Internal method used to add the `DelegatingHandlerInitializer` provided
    /// by the `DefinitionWithDelegatingHandler` to the `ContextNode`.
    ///
    /// Note, this method does nothing, if self also conforms to `DefinitionWithDelegatingHandlerKey`.
    /// - Parameter visitor: The `SyntaxTreeVisitor`.
    func addInitializerContextValue(_ visitor: SyntaxTreeVisitor)
}

/// Some `MetadataDefinition` might declare conformance to `DefinitionWithDelegatingHandler`
/// if it wishes to bootstrap an `DelegatingHandlerInitializer` for the respective `Component`, `WebService` and/or `Handler`.
/// This protocol shall be used if the Initializer is supplied in addition to the `ContextKey` provided
/// by the `MetadataDefinition`.
/// If `MetadataDefinition` solely provides a `DelegatingHandlerInitializer`, use `DefinitionWithDelegatingHandlerKey`.
///
/// Note, this conformance has no effects when used with a `ContentMetadata`.
public protocol DefinitionWithDelegatingHandler: AnyDefinitionWithDynamicDelegatingHandler where Self: MetadataDefinition {
    associatedtype Initializer: DelegatingHandlerInitializer

    /// Provides the respective `DelegatingHandlerInitializer`.
    var initializer: Initializer { get }

    /// Defines if the Initializer shall be prepended to the list of initializers.
    /// Note: While the property can be freely implemented, it is advised to NOT touch it.
    ///   Using prepend=ture on `MetadataDefinition` creates am unintuitive parsing order,
    ///   where the Delegating Handler of a Metadata parsed second is placed first.
    var prepend: Bool { get }
}

/// Some `MetadataDefinition` might declare conformance to `DefinitionWithDelegatingHandlerKey`
/// if it wishes (and only wishes; meaning doesn't expose any other Context values) to boostrap an
/// `DelegatingHandlerInitializer` for the respective `Component`, `WebService` and/or `Handler`.
/// Therefore this protocol sets the `MetadataDefinition.Key` associated type.
public protocol DefinitionWithDelegatingHandlerKey: DefinitionWithDelegatingHandler {
    typealias Key = DelegatingHandlerContextKey
}

public extension DefinitionWithDelegatingHandler {
    /// Default is false. See note in `DefinitionWithDelegatingHandler.prepend`.
    var prepend: Bool {
        false
    }

    /// Default implementation for adding the initializer context key.
    func addInitializerContextValue(_ visitor: SyntaxTreeVisitor) {
        guard Self.Key.self != DelegatingHandlerContextKey.self else {
            return
        }

        visitor.addContext(DelegatingHandlerContextKey.self, value: [(prepend, initializer)], scope: Self.scope)
    }
}

public extension DefinitionWithDelegatingHandler where Self.Key == DelegatingHandlerContextKey {
    /// Default value for `MetadataDefinitions` with `DelegatingHandlerContextKey`.
    /// It assembles the value for the `DelegatingHandlerContextKey`.
    var value: Self.Key.Value {
        [(self.prepend, self.initializer)]
    }
}
