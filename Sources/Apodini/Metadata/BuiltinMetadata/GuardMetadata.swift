//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

public extension TypedHandlerMetadataNamespace {
    /// Name Definition for the ``GuardMetadata``
    typealias Guarded = GuardMetadata<Self>
}

/// The ``GuardMetadata`` can be used to add a ``Guard`` or ``SyncGuard`` to a ``Handler``.
///
/// The Metadata is available under the `Handler/Guarded` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         Guarded(by: SomeGuard())
///     }
/// }
/// ```
public struct GuardMetadata<H: Handler>: HandlerMetadataDefinition, DefinitionWithDelegatingHandlerKey {
    public let initializer: DelegatingHandlerContextKey.Entry

    /// Use an asynchronous ``Guard`` to guard ``Handler``s by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    public init<G: Guard>(by guard: G) {
        self.initializer = .init(GuardingHandlerInitializer<G, H.Response>(guard: `guard`))
    }

    /// Use a synchronous ``SyncGuard`` to guard ``Handler``s by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    public init<G: SyncGuard>(by guard: G) {
        self.initializer = .init(SyncGuardingHandlerInitializer<G, H.Response>(guard: `guard`))
    }
}


public extension HandlerMetadataNamespace {
    /// Name Definition for the ``ResetGuardsMetadata``
    typealias ResetGuards = ResetGuardsMetadata
}

/// The ``ResetGuardsMetadata`` can be used to reset all guards for a given ``Handler``.
/// It applies to guards which are declared in the same Metadata Block and are declared above
/// this Metadata (see example below).
///
/// The Metadata is available under the `Handler/ResetGuards` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         Guarded(by: SomeGuard1()) // will be reset
///         ResetGuards()
///         Guarded(by: SomeGuard2()) // won't be reset
///     }
/// }
/// ```
public struct ResetGuardsMetadata: HandlerMetadataDefinition, DefinitionWithDelegatingHandlerKey {
    public let initializer: DelegatingHandlerContextKey.Entry

    /// Resets all guards for the modified ``Component``
    public init() {
        self.initializer = .init(AnyDelegateFilter(filter: GuardFilter()))
    }
}
