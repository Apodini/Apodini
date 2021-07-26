//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

public extension HandlerMetadataNamespace {
    /// Name Definition for the ``ResetMetadata``
    typealias Reset = ResetMetadata
}

/// The ``ResetGuardsMetadata`` can be used to filter out ``DelegatingHandlerInitializer``s on a given ``Handler``.
/// It applies to ``DelegatingHandlerInitializer`` which are declared in the same Metadata Block and are declared above
/// this Metadata (see example below).
///
/// The Metadata is available under the `Handler/ResetGuards` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         Delegated(by: SomeDelegatingHandlerInitializer1()) // will be evaluated against the filter
///         Reset(using: SomeFilter())
///         Guarded(by: SomeDelegatingHandlerInitializer2()) // won't be evaluated against the filter
///     }
/// }
/// ```
public struct ResetMetadata: HandlerMetadataDefinition, DefinitionWithDelegatingHandlerKey {
    public let initializer: DelegatingHandlerContextKey.Entry

    /// Use a `DelegationFilter` to filter out `DelegatingHandlerInitializer`s.
    /// - Parameters:
    ///   - ensureInitializerTypeUniqueness: If set to true, it is ensured that the same ``DelegationFilter``
    ///     is only used a single time, even when inserted multiple times.
    public init(using filter: DelegationFilter, ensureInitializerTypeUniqueness: Bool = false) {
        self.initializer = .init(AnyDelegateFilter(filter: filter), ensureInitializerTypeUniqueness: ensureInitializerTypeUniqueness)
    }
}
