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

public struct LicenseContextKey: OptionalContextKey {
    public typealias Value = OpenAPIKit.OpenAPI.Document.Info.License
}

public extension WebServiceMetadataNamespace {
    /// Name definition for the ``LicenseMetadata``
    typealias License = LicenseMetadata
}

/// The ``ContactMetadata`` can be used to define license information for the OpenAPI Specification for the `WebService`.
///
/// The Metadata is available under the `WebServiceMetadataNamespace/License` name and can be used like the following:
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         License(name: "MIT", url: URL(string: "https://license.some-corp.com"))
///     }
/// }
/// ```
public struct LicenseMetadata: WebServiceMetadataDefinition {
    public typealias Key = LicenseContextKey

    public let value: Key.Value

    public init(name: String, url: URL? = nil, vendorExtensions: [String: AnyEncodable] = [:]) {
        self.value = .init(name: name, url: url, vendorExtensions: vendorExtensions.mapToOpenAPICodable())
    }
}
