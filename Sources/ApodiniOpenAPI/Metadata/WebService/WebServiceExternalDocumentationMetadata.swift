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

public struct WebServiceExternalDocsContextKey: OptionalContextKey {
    public typealias Value = OpenAPIKit.OpenAPI.ExternalDocumentation
}

public extension WebServiceMetadataNamespace {
    /// Name definition for the ``WebServiceExternalDocumentationMetadata``.
    typealias ExternalDocumentation = WebServiceExternalDocumentationMetadata
}

/// The ``WebServiceExternalDocumentationMetadata`` can be used to define external documentation for
/// the OpenAPI Specification for the `WebService`.
///
/// The Metadata is available under the `WebServiceMetadataNamespace/ExternalDocumentation` name and can be used like the following:
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         ExternalDocumentation(
///             description: "Follow the link for the external documentation",
///             url: URL(string: "https://docs.some-corp.com")!
///         )
///     }
/// }
/// ```
public struct WebServiceExternalDocumentationMetadata: WebServiceMetadataDefinition {
    public typealias Key = WebServiceExternalDocsContextKey

    public let value: Key.Value

    public init(description: String? = nil, url: URL, vendorExtensions: [String: AnyCodable] = [:]) {
        self.value = .init(description: description, url: url, vendorExtensions: vendorExtensions)
    }
}
