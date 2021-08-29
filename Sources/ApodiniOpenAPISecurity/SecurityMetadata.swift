//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import OpenAPIKit
import ApodiniUtils

public struct OpenAPISecurityContextKey: ContextKey {
    public typealias Value = [ApodiniSecurityScheme]
    public static let defaultValue: Value = []

    public static func reduce(value: inout Value, nextValue: Value) {
        value.append(contentsOf: nextValue)
    }
}

public extension ComponentMetadataNamespace {
    /// Name definition for the ``SecurityMetadata``
    typealias Security = SecurityMetadata
}

/// The ``SecurityMetadata`` can be used to define security information for the OpenAPI Specification for a ``Component``.
///
/// The Metadata is available under the ``ComponentMetadataNamespace/Security`` name and can be used like the following:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         Security(name: "basic_credentials", .http(scheme: "basic"))
///     }
/// }
/// ```
public struct SecurityMetadata: ComponentMetadataDefinition {
    public typealias Key = OpenAPISecurityContextKey

    public let value: OpenAPISecurityContextKey.Value

    public init(
        name: String? = nil,
        _ scheme: ApodiniSecurityType,
        description: String? = nil,
        required: Bool = true,
        vendorExtensions: [String: AnyEncodable] = [:]
    ) {
        self.value = [.init(name: name, type: scheme, description: description, required: required, vendorExtensions: vendorExtensions)]
    }
}
