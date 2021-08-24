//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

public struct TermsOfServiceContextKey: OptionalContextKey {
    public typealias Value = URL
}

public extension WebServiceMetadataNamespace {
    /// Name definition for the ``TermsOfServiceMetadata``
    typealias TermsOfService = TermsOfServiceMetadata
}

/// The ``TermsOfServiceMetadata`` can be used to define terms of service for the OpenAPI Specification for the ``WebService``.
///
/// The Metadata is available under the ``WebServiceMetadataNamespace/TermsOfService`` name and can be used like the following:
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         TermsOfService(url: URL(string: "https://terms.some-corp.com")!)
///     }
/// }
/// ```
public struct TermsOfServiceMetadata: WebServiceMetadataDefinition {
    public typealias Key = TermsOfServiceContextKey

    public let value: URL

    public init (url: URL) {
        self.value = url
    }
}
