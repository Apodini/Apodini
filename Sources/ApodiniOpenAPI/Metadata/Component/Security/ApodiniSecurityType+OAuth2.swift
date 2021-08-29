//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniOpenAPISecurity
import OpenAPIKit

public extension ApodiniSecurityType {
    /// Create an oauth2 security type.
    /// - Parameters:
    ///   - flows: An object containing configuration information for the supported flow types.
    ///   - scopes: The list of scopes names required for the execution of the given endpoint.
    static func oauth2(flows: OpenAPIKit.OpenAPI.OAuthFlows, scopes: [String]) -> ApodiniSecurityType {
        ApodiniSecurityType(
            type: .openAPIScheme(OpenAPIKit.OpenAPI.SecurityScheme.SecurityType.oauth2(flows: flows)),
            scopes: scopes
        )
    }

    /// Create an oauth2 security type.
    /// - Parameters:
    ///   - flows: An object containing configuration information for the supported flow types.
    ///   - scopes: The list of scopes names required for the execution of the given endpoint.
    static func oauth2(flows: OpenAPIKit.OpenAPI.OAuthFlows, scopes: String...) -> ApodiniSecurityType {
        oauth2(flows: flows, scopes: scopes)
    }
}
