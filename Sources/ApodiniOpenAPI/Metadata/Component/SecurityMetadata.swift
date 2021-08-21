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
    public typealias Value = OpenAPIKit.OpenAPI.ComponentDictionary<ApodiniSecurityScheme>
    public static let defaultValue: Value = [:]

    public static func reduce(value: inout Value, nextValue: Value) {
        for (key, entry) in nextValue {
            value[key] = entry
        }
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
        vendorExtensions: [String: AnyCodable] = [:]
    ) {
        guard let key: OpenAPIKit.OpenAPI.ComponentKey = .init(rawValue: name ?? "\(UUID())") else {
            fatalError("Security Metadata Key must match pattern '^[a-zA-Z0-9\\.\\-_]+$'")
        }
        self.value = [key: .init(type: scheme, description: description, required: required, vendorExtensions: vendorExtensions)]
    }

    public init(
        name: String? = nil,
        openAPIScheme: OpenAPIKit.OpenAPI.SecurityScheme.SecurityType,
        description: String? = nil,
        required: Bool = true,
        vendorExtensions: [String: AnyCodable] = [:]
    ) {
        self.init(
            name: name,
            ApodiniSecurityType(type: .openAPI(openAPIScheme)),
            description: description,
            required: required,
            vendorExtensions: vendorExtensions
        )
    }
}

struct EndpointSecurityDescription {
    let scheme: OpenAPIKit.OpenAPI.SecurityScheme
    let required: Bool
    let scopes: [String]
}


/// Apodini intermediate representation for an OpenAPIKit `SecurityScheme`.
/// See https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#securitySchemeObject
public struct ApodiniSecurityScheme {
    let type: ApodiniSecurityType
    let description: String?
    let required: Bool
    let vendorExtensions: [String: AnyCodable]

    func mapToOpenAPISecurity<H: Handler>(on endpoint: Endpoint<H>) -> EndpointSecurityDescription {
        EndpointSecurityDescription(
            scheme: .init(type: type.mapToOpenAPISecurity(on: endpoint), description: description, vendorExtensions: vendorExtensions),
            required: required,
            scopes: type.scopes
        )
    }
}

extension OrderedDictionary where Key == OpenAPIKit.OpenAPI.ComponentKey, Value == ApodiniSecurityScheme {
    func mapToOpenAPISecurity<H: Handler>(on endpoint: Endpoint<H>) -> OpenAPIKit.OpenAPI.ComponentDictionary<EndpointSecurityDescription> {
        mapValues { apodiniSecurity in
            apodiniSecurity.mapToOpenAPISecurity(on: endpoint)
        }
    }
}

/// Apodini intermediate representation for an OpenAPIKit `SecurityType`.
public struct ApodiniSecurityType {
    let type: SchemeType
    let scopes: [String]

    init(type: SchemeType, scopes: [String] = []) {
        self.type = type
        self.scopes = scopes
    }

    /// Creates an api key security type.
    /// - Parameters:
    ///   - name: The name of the header, query or cookie parameter to be used.
    ///   - location: The location of the API Key.
    public static func apiKey(name: String, location: OpenAPIKit.OpenAPI.SecurityScheme.Location) -> ApodiniSecurityType {
        ApodiniSecurityType(type: .openAPI(.apiKey(name: name, location: location)))
    }

    /// Creates an api key security type.
    /// - Parameters:
    ///   - binding: Defines the location and name of the api key by passing the Binding of a Apodini `Parameter`.
    ///     Note, that OpenAPI only supports api keys passed in as query parameter, and not as path or content parameter.
    public static func apiKey<Element>(at binding: Binding<Element>) -> ApodiniSecurityType {
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
    public static func http(scheme: String, bearerFormat: String? = nil) -> ApodiniSecurityType {
        ApodiniSecurityType(type: .openAPI(.http(scheme: scheme, bearerFormat: bearerFormat)))
    }


    /// Create an oauth2 security type.
    /// - Parameters:
    ///   - flows: An object containing configuration information for the supported flow types.
    ///   - scopes: The list of scopes names required for the execution of the given endpoint.
    public static func oauth2(flows: OpenAPIKit.OpenAPI.OAuthFlows, scopes: [String]) -> ApodiniSecurityType {
        ApodiniSecurityType(type: .openAPI(.oauth2(flows: flows)), scopes: scopes)
    }

    /// Create an oauth2 security type.
    /// - Parameters:
    ///   - flows: An object containing configuration information for the supported flow types.
    ///   - scopes: The list of scopes names required for the execution of the given endpoint.
    public static func oauth2(flows: OpenAPIKit.OpenAPI.OAuthFlows, scopes: String...) -> ApodiniSecurityType {
        oauth2(flows: flows, scopes: scopes)
    }


    /// Create an OpenId Connect security type.
    /// - Parameters:
    ///   - url: OpenId Connect URL to discovery OAuth2 configuration values. TLS is mandated by the OpenId Connect standard.
    ///   - scopes: The list of scopes names required for the execution of the given endpoint.
    public static func openIdConnect(url: URL, scopes: [String]) -> ApodiniSecurityType {
        ApodiniSecurityType(type: .openAPI(.openIdConnect(openIdConnectUrl: url)), scopes: scopes)
    }

    /// Create an OpenId Connect security type.
    /// - Parameters:
    ///   - url: OpenId Connect URL to discovery OAuth2 configuration values. TLS is mandated by the OpenId Connect standard.
    ///   - scopes: The list of scopes names required for the execution of the given endpoint.
    public static func openIdConnect(url: URL, scopes: String...) -> ApodiniSecurityType {
        openIdConnect(url: url, scopes: scopes)
    }


    func mapToOpenAPISecurity<H: Handler>(on endpoint: Endpoint<H>) -> OpenAPIKit.OpenAPI.SecurityScheme.SecurityType {
        switch type {
        case .openAPI(let type):
            return type
        case .parameterAPIKey(let parameterId):
            guard let parameter = endpoint.parameters.first(where: { $0.id == parameterId }) else {
                fatalError("Could not find parameter for binding \(parameterId)")
            }

            guard parameter.parameterType == .lightweight else {
                fatalError("Path or content parameter cannot be used to in OpenAPI specification for an API Key!")
            }

            return .apiKey(name: parameter.name, location: .query)
        }
    }

    enum SchemeType {
        case openAPI(_ type: OpenAPIKit.OpenAPI.SecurityScheme.SecurityType)
        case parameterAPIKey(parameter: UUID)
    }
}
