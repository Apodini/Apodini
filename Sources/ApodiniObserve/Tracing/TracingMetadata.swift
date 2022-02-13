//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

///
public struct TracingContextKey: OptionalContextKey {
    public typealias Value = Bool
}

extension ComponentMetadataNamespace {
    /// Typealias for `TracingMetadata`.
    public typealias Tracing = TracingMetadata
}

/// The `TracingMetadata` can be used to enable or disable tracing for a component.
///
/// The Metadata is available under the `ComponentMetadataNamespace` and can be used as follows:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         Tracing(isEnabled: true)
///     }
/// }
/// ```
public struct TracingMetadata: ComponentMetadataDefinition, DefinitionWithDelegatingHandler {
    public typealias Key = TracingContextKey

    public var value: Bool

    public var initializer: DelegatingHandlerContextKey.Value {
        value ? [.init(TracingHandlerInitializer())] : []
    }

    public init(isEnabled: Bool) {
        self.value = isEnabled
    }
}

extension Component {
    /// A `trace` modifier can be used to enable or disable tracing for a `Component` using `TracingMetadata`.
    /// - Parameter isEnabled: Boolean indicating of tracing should be enabled or disabled.
    /// - Returns: The modified `Component` with `TracingMetadata` attached.
    public func trace(isEnabled: Bool = true) -> ComponentMetadataModifier<Self> {
        self.metadata(TracingMetadata(isEnabled: isEnabled))
    }
}
