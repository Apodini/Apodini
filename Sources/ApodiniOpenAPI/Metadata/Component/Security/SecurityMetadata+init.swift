//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniUtils
import ApodiniOpenAPISecurity
import OpenAPIKit


public extension SecurityMetadata {
    /// Fallback initializes if you are required to rely on the OpenAPIKit types.
    init(
        name: String? = nil,
        openAPIScheme: OpenAPIKit.OpenAPI.SecurityScheme.SecurityType,
        description: String? = nil,
        required: Bool = true,
        vendorExtensions: [String: AnyEncodable] = [:]
    ) {
        self.init(
            name: name,
            ApodiniSecurityType(type: .openAPIScheme(openAPIScheme)),
            description: description,
            required: required,
            vendorExtensions: vendorExtensions
        )
    }
}
