//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

public struct APIVersionContextKey: ContextKey {
    public typealias Value = Version
    public static var defaultValue = Version()
}

public extension WebServiceMetadataNamespace {
    /// Name definition for the ``WebServiceVersionMetadata``
    typealias Version = WebServiceVersionMetadata
}

/// The ``WebServiceVersionMetadata`` can be used to define the ``Version`` of the ``WebService``.
///
/// The Metadata is available under the ``WebServiceMetadataNamespace/Version`` name and can be used like the following:
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         Version(major: 1, minor: 2)
///     }
/// }
/// ```
public struct WebServiceVersionMetadata: WebServiceMetadataDefinition {
    public typealias Key = APIVersionContextKey

    public let value: Version

    public init(prefix: String = Version.Defaults.prefix,
                major: UInt = Version.Defaults.major,
                minor: UInt = Version.Defaults.minor,
                patch: UInt = Version.Defaults.patch) {
        self.value = Version(prefix: prefix, major: major, minor: minor, patch: patch)
    }
}
