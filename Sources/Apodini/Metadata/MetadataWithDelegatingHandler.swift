//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// A type erased ``DefinitionWithDelegatingHandler``.
public protocol AnyDefinitionWithDynamicDelegatingHandler {
    /// Internal method used to add the ``DelegatingHandlerInitializer`` provided
    /// by the ``DefinitionWithDelegatingHandler`` to the `ContextNode`.
    ///
    /// Note, this method does nothing, if self also conforms to ``DefinitionWithDelegatingHandlerKey``.
    /// - Parameter visitor: The `MetadataParser`.
    func addInitializerContextValue<Parser: MetadataParser>(_ visitor: Parser)
}

/// Some ``MetadataDefinition`` might declare conformance to ``DefinitionWithDelegatingHandler``
/// if it wishes to bootstrap an ``DelegatingHandlerInitializer`` for the respective ``Component``, ``WebService`` and/or ``Handler``.
/// This protocol shall be used if the Initializer is supplied in addition to the ``OptionalContextKey`` provided
/// by the ``MetadataDefinition``.
/// If ``MetadataDefinition`` solely provides a ``DelegatingHandlerInitializer``, use ``DefinitionWithDelegatingHandlerKey``.
///
/// Note, this conformance has no effects when used with a `ContentMetadata`.
public protocol DefinitionWithDelegatingHandler: AnyDefinitionWithDynamicDelegatingHandler where Self: MetadataDefinition {
    /// Provides the respective Value for the ``DelegatingHandlerContextKey``.
    var initializer: DelegatingHandlerContextKey.Value { get }
}

/// Some ``MetadataDefinition`` might declare conformance to ``DefinitionWithDelegatingHandlerKey``
/// if it wishes (and only wishes; meaning doesn't expose any other Context values) to bootstrap an
/// ``DelegatingHandlerInitializer`` for the respective ``Component``, ``WebService`` and/or ``Handler``.
/// Therefore this protocol sets the ``MetadataDefinition/Key`` associated type.
public protocol DefinitionWithDelegatingHandlerKey: DefinitionWithDelegatingHandler {
    typealias Key = DelegatingHandlerContextKey
}

public extension DefinitionWithDelegatingHandler {
    /// Default implementation for adding the initializer context key.
    func addInitializerContextValue<Parser: MetadataParser>(_ visitor: Parser) {
        guard Self.Key.self != DelegatingHandlerContextKey.self else {
            return
        }

        visitor.addContext(DelegatingHandlerContextKey.self, value: initializer, scope: Self.scope)
    }
}

public extension DefinitionWithDelegatingHandler where Self.Key == DelegatingHandlerContextKey {
    /// Default value for ``MetadataDefinition``s with ``DelegatingHandlerContextKey``.
    /// It assembles the value for the ``DelegatingHandlerContextKey``.
    var value: Self.Key.Value {
        self.initializer
    }
}
