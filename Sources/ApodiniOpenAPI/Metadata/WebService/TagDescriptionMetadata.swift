//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import OpenAPIKit

public struct OpenAPITagDescription: OptionalContextKey {
    public typealias Value = [OpenAPIKit.OpenAPI.Tag]
}

public extension WebServiceMetadataNamespace {
    /// Name definition for the ``TagDescriptionMetadata``.
    typealias TagDescription = TagDescriptionMetadata

    /// Defines a ``WebServiceMetadataBlock`` you can use to group your ``WebServiceMetadataNamespace/TagDescription`` Metadata.
    ///
    /// ```swift
    /// struct ExampleWebService: WebService {
    ///     // ...
    ///     var metadata: Metadata {
    ///         TagDescriptions {
    ///             // ...
    ///         }
    ///     }
    /// }
    /// ```
    typealias TagDescriptions = RestrictedWebServiceMetadataBlock<TagDescription>
}

/// The ``TagDescriptionMetadata`` can be used to define tag documentation for the OpenAPI Specification for the ``WebService``.
///
/// The Metadata is available under the ``WebServiceMetadataNamespace/TagDescription`` name and can be used like the following:
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         TagDescription(name: "authentication", description: "Groups all authentication endpoints")
///     }
/// }
/// ```
public struct TagDescriptionMetadata: WebServiceMetadataDefinition {
    public typealias Key = OpenAPITagDescription

    public let value: OpenAPITagDescription.Value

    public init(
        name: String,
        description: String? = nil,
        externalDocs: OpenAPIKit.OpenAPI.ExternalDocumentation? = nil,
        vendorExtensions: [String: AnyCodable] = [:]
    ) {
        self.value = [.init(name: name, description: description, externalDocs: externalDocs, vendorExtensions: vendorExtensions)]
    }
}
