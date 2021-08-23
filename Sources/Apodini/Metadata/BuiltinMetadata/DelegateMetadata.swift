//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

public extension TypedHandlerMetadataNamespace {
    /// Name Definition for the ``DelegateMetadata``
    typealias Delegated = DelegateMetadata<Self>
}

/// The ``DelegateMetadata`` can be used to add a ``DelegatingHandlerInitializer`` to a ``Handler``.
///
/// Any ``DelegatingHandlerInitializer`` added as a metadata MUST match the response type of the delegated ``Handler``.
///
/// The Metadata is available under the `Handler/Delegated` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         Delegated(by: SomeDelegatingHandlerInitializer())
///     }
/// }
/// ```
public struct DelegateMetadata<H: Handler>: HandlerMetadataDefinition, DefinitionWithDelegatingHandlerKey {
    public let initializer: DelegatingHandlerContextKey.Value

    /// Creates a new Delegate metadata.
    /// - Parameters:
    ///   - initializer: The respective ``DelegatingHandlerInitializer``
    ///   - ensureInitializerTypeUniqueness: If set to true, it is ensured that the same ``DelegatingHandlerInitializer``
    ///     is only used a single time, even when inserted multiple times.
    ///   - inverseOrder: Set this to true if the according DelegatingHandler should act on the output of
    ///     the delegated Handler. Those Handler typically call the delegate first and then execute their own logic.
    ///     Therefore, such an initializer which is added first, should be inserted on the "innerst" position not
    ///     the "outerst", as it should be the first to act once handle returns.
    public init<I: DelegatingHandlerInitializer>(by initializer: I, ensureInitializerTypeUniqueness: Bool = false, inverseOrder: Bool = false)
        where I.Response == H.Response {
        self.initializer = [.init(initializer, ensureInitializerTypeUniqueness: ensureInitializerTypeUniqueness, inverseOrder: inverseOrder)]
    }
}
