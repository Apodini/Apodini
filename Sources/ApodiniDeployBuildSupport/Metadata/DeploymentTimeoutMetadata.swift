//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

/// The `TimeoutValue` struct can be used as an option's value, and represents a time interval in seconds
public struct TimeoutValue: PropertyOptionWithDefault, RawRepresentable {
    public static var defaultValue: TimeoutValue {
        .seconds(4)
    }

    /// timeout in seconds
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static func & (lhs: TimeoutValue, rhs: TimeoutValue) -> TimeoutValue {
        TimeoutValue(rawValue: max(lhs.rawValue, rhs.rawValue))
    }

    public static func seconds(_ value: UInt) -> TimeoutValue {
        TimeoutValue(rawValue: value)
    }

    public static func minutes(_ value: UInt) -> TimeoutValue {
        TimeoutValue(rawValue: value * 60)
    }
}

public extension PropertyOptionKey where PropertyNameSpace == DeploymentOptionNamespace, Option == TimeoutValue {
    /// The ``PropertyOptionKey`` for ``TimeoutValue``.
    static let timeoutValue = DeploymentOptionKey<TimeoutValue>()
}


public extension ComponentMetadataNamespace {
    /// Name definition for the ``DeploymentTimeoutMetadata``
    typealias Timeout = DeploymentTimeoutMetadata
}

/// The ``DeploymentTimeoutMetadata`` can be used to explicitly declare the ``TimeoutValue`` deployment option.
///
/// The Metadata is available under the `ComponentMetadataNamespace/Timeout` name and can be used like the following:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         Timeout(.seconds(4))
///     }
/// }
/// ```
public struct DeploymentTimeoutMetadata: ComponentMetadataDefinition {
    public typealias Key = DeploymentOptionsContextKey

    public let value: PropertyOptionSet<DeploymentOptionNamespace>

    public init(_ value: TimeoutValue) {
        self.value = .init(value, for: .timeoutValue)
    }
}
