//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniUtils
import ApodiniOpenAPISecurity
import OpenAPIKit

struct EndpointSecurityDescription: SomeSecurityDescription {
    let scheme: OpenAPIKit.OpenAPI.SecurityScheme
    let required: Bool
    let scopes: [String]
}


extension OpenAPIKit.OpenAPI.SecurityScheme: OpenAPISecurityScheme {
    public init(
        type: OpenAPIKit.OpenAPI.SecurityScheme.SecurityType,
        description: String?,
        vendorExtensions: [String: AnyEncodable]
    ) {
        self.init(type: type, description: description, vendorExtensions: vendorExtensions.mapToOpenAPICodable())
    }
}


extension OpenAPIKit.OpenAPI.SecurityScheme.SecurityType: OpenAPISecurityType {
    public static func mapType<H: Handler>(from type: ApodiniSecurityType.SchemeType, on endpoint: Endpoint<H>) -> Self {
        switch type {
        case let .openAPIScheme(scheme):
            return scheme.openAPITyped()
        case let .apiKey(name, location):
            return .apiKey(name: name, location: location.openAPIType)
        case let .parameterAPIKey(parameterId):
            guard let parameter = endpoint.parameters.first(where: { $0.id == parameterId }) else {
                fatalError("Could not find parameter for binding \(parameterId)")
            }
            guard parameter.parameterType == .lightweight else {
                fatalError("Path or content parameter cannot be used to in OpenAPI specification for an API Key!")
            }

            return .apiKey(name: parameter.name, location: .query)
        case let .http(scheme, bearerFormat):
            return .http(scheme: scheme, bearerFormat: bearerFormat)
        case let .openIdConnect(url):
            return .openIdConnect(openIdConnectUrl: url)
        }
    }
}


extension OpenAPISecurityType {
    func openAPITyped() -> OpenAPIKit.OpenAPI.SecurityScheme.SecurityType {
        guard let typed = self as? OpenAPIKit.OpenAPI.SecurityScheme.SecurityType else {
            fatalError("Failed to cast `OpenAPISecurityType` with type \(type(of: self)) to `OpenAPI.SecurityScheme.SecurityType`!")
        }
        return typed
    }
}
