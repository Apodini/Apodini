//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

/// Apodini intermediate representation for an OpenAPIKit security type.
public struct ApodiniSecurityType {
    let type: SchemeType
    let scopes: [String]

    /// Initializes a new ``ApodiniSecurityType``
    /// - Parameters:
    ///   - type: The ``ApodiniSecurityType/SchemeType``.
    ///   - scopes: Array of required scopes for the endpoint, if applicable for oauth based types.
    public init(type: SchemeType, scopes: [String] = []) {
        self.type = type
        self.scopes = scopes
    }

    /// Defines the internally stored security scheme type.
    /// Those are intermediate representation for the `OpenAPIKit.OpenAPI.SecurityScheme.SchemeType`
    public enum SchemeType {
        /// An api key scheme type, providing the property name and its location.
        case apiKey(name: String, location: ApodiniSecurityScheme.Location)
        /// An ``apiKey(name:location:)`` ``SchemeType`` which is specified by providing a reference to a query `@Parameter`.
        case parameterAPIKey(parameter: UUID)
        /// A http scheme type providing the http `scheme` and, if applicable, the `bearerFormat`.
        case http(scheme: String, bearerFormat: String?)
        /// Specifies an OpenId Connect scheme type.
        case openIdConnect(openIdConnectUrl: URL)
        /// Transports an arbitrary `OpenAPIKit.OpenAPI.SecurityScheme.SchemeType` instance.
        case openAPIScheme(_ scheme: OpenAPISecurityType)
    }
}


public extension ApodiniSecurityType {
    // Mirrors most of OpenAPI initializers, only thing missing is the func to create oAuth flows.
    // As we currently don't need it, there is no reason to maintain a copy of such a huge data structure.

    /// Creates an api key security type.
    /// - Parameters:
    ///   - name: The name of the header, query or cookie parameter to be used.
    ///   - location: The location of the API Key.
    static func apiKey(name: String, location: ApodiniSecurityScheme.Location) -> ApodiniSecurityType {
        ApodiniSecurityType(type: .apiKey(name: name, location: location))
    }

    /// Creates an api key security type.
    /// - Parameters:
    ///   - binding: Defines the location and name of the api key by passing the Binding of a Apodini `Parameter`.
    ///     Note, that OpenAPI only supports api keys passed in as query parameter, and not as path or content parameter.
    static func apiKey<Element>(at binding: Binding<Element>) -> ApodiniSecurityType {
        guard let id = _Internal.getParameterId(ofBinding: binding) else {
            preconditionFailure("Security Metadata with type `apiKey` can only be constructed from a Binding of a @Parameter!")
        }
        // we save the uuid to later reconstruct the parameter name and location
        return ApodiniSecurityType(type: .parameterAPIKey(parameter: id))
    }


    /// Create a http security type.
    /// - Parameters:
    ///   - scheme: The name of the HTTP Authorization scheme to be used.
    ///   - bearerFormat: Supplied when scheme equals to `"bearer"`.
    ///     A hint to the client to identify how the bearer token is formatted.
    static func http(scheme: String, bearerFormat: String? = nil) -> ApodiniSecurityType {
        ApodiniSecurityType(type: .http(scheme: scheme, bearerFormat: bearerFormat))
    }

    /// Create an OpenId Connect security type.
    /// - Parameters:
    ///   - url: OpenId Connect URL to discovery OAuth2 configuration values. TLS is mandated by the OpenId Connect standard.
    ///   - scopes: The list of scopes names required for the execution of the given endpoint.
    static func openIdConnect(url: URL, scopes: [String]) -> ApodiniSecurityType {
        ApodiniSecurityType(type: .openIdConnect(openIdConnectUrl: url), scopes: scopes)
    }

    /// Create an OpenId Connect security type.
    /// - Parameters:
    ///   - url: OpenId Connect URL to discovery OAuth2 configuration values. TLS is mandated by the OpenId Connect standard.
    ///   - scopes: The list of scopes names required for the execution of the given endpoint.
    static func openIdConnect(url: URL, scopes: String...) -> ApodiniSecurityType {
        openIdConnect(url: url, scopes: scopes)
    }
}
