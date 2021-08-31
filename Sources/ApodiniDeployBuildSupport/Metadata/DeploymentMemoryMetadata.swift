//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public struct MemorySize: PropertyOptionWithDefault, RawRepresentable {
    public static var defaultValue: MemorySize {
        .mb(128)
    }

    /// memory size, in MB
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static func mb(_ value: UInt) -> Self {
        .init(rawValue: value)
    }

    public static func & (lhs: MemorySize, rhs: MemorySize) -> MemorySize {
        MemorySize(rawValue: max(lhs.rawValue, rhs.rawValue))
    }
}

public extension PropertyOptionKey where PropertyNameSpace == DeploymentOptionNamespace, Option == MemorySize {
    /// The ``PropertyOptionKey`` for ``MemorySize``.
    static let memorySize = DeploymentOptionKey<MemorySize>()
}

public extension ComponentMetadataNamespace {
    /// Name definition for the ``DeploymentMemoryMetadata``
    typealias Memory = DeploymentMemoryMetadata
}

/// The ``DeploymentMemoryMetadata`` can be used to explicitly declare the ``MemorySize`` deployment option.
///
/// The Metadata is available under the `ComponentMetadataNamespace/Memory` name and can be used like the following:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         Memory(.mb(128))
///     }
/// }
/// ```
public struct DeploymentMemoryMetadata: ComponentMetadataDefinition {
    public typealias Key = DeploymentOptionsContextKey

    public let value: PropertyOptionSet<DeploymentOptionNamespace>

    public init(_ value: MemorySize) {
        self.value = .init(value, for: .memorySize)
    }
}
