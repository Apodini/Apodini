//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniUtils

/// A type erased version of `OpenAPIKit.OpenAPI.SecurityScheme`.
public protocol OpenAPISecurityScheme {
    /// The associated ``OpenAPISecurityType``.
    associatedtype SecurityType: OpenAPISecurityType

    /// Initializes a new ``OpenAPISecurityScheme``.
    init(type: SecurityType, description: String?, vendorExtensions: [String: AnyEncodable])
}
