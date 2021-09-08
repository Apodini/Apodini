//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniUtils
import OpenAPIKit

public struct ContactContextKey: OptionalContextKey {
    public typealias Value = OpenAPIKit.OpenAPI.Document.Info.Contact
}

public extension WebServiceMetadataNamespace {
    /// Name definition for the ``ContactMetadata``
    typealias Contact = ContactMetadata
}

/// The ``ContactMetadata`` can be used to define contact information for the OpenAPI Specification for the ``WebService``.
///
/// The Metadata is available under the ``WebServiceMetadataNamespace/Contact`` name and can be used like the following:
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         Contact(name: "SomeCorp", email: "info@some-corp.com")
///     }
/// }
/// ```
public struct ContactMetadata: WebServiceMetadataDefinition {
    public typealias Key = ContactContextKey

    public var value: Key.Value

    public init(name: String? = nil, url: URL? = nil, email: String? = nil, vendorExtensions: [String: AnyEncodable] = [:]) {
        self.value = .init(name: name, url: url, email: email, vendorExtensions: vendorExtensions.mapToOpenAPICodable())
    }
}
