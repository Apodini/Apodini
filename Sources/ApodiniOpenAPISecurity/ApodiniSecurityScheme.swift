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
import OrderedCollections

/// Apodini intermediate representation for an OpenAPIKit `SecurityScheme`.
/// See https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#securitySchemeObject
public struct ApodiniSecurityScheme {
    let name: String?
    let type: ApodiniSecurityType
    let description: String?
    let required: Bool
    let vendorExtensions: [String: AnyEncodable]
}

// MARK: Location
public extension ApodiniSecurityScheme {
    enum Location: String {
        case query
        case header
        case cookie
    }
}

public extension ApodiniSecurityScheme {
    /// Maps the generalized Apodini ``ApodiniSecurityScheme`` to the supplied ``SomeSecurityDescription``.
    /// Mapping happens in the context of a dedicated endpoint (e.g. to considered declared parameters).
    func map<Description: SomeSecurityDescription, H: Handler>(
        to description: Description.Type = Description.self,
        on endpoint: Endpoint<H>
    ) -> Description {
        Description(
            scheme: .init(
                type: .mapType(from: type.type, on: endpoint),
                description: self.description,
                vendorExtensions: vendorExtensions
            ),
            required: required,
            scopes: type.scopes
        )
    }
}

extension Array where Element == ApodiniSecurityScheme {
    /// Maps an array of generalized Apodini ``ApodiniSecurityScheme`` to the supplied ``SomeSecurityDescription``.
    /// Mapping happens in the context of a dedicated endpoint (e.g. to considered declared parameters).
    public func map<Description: SomeSecurityDescription, H: Handler>(
        to description: Description.Type = Description.self,
        on endpoint: Endpoint<H>
    ) -> OrderedDictionary<String, Description> {
        reduce(into: [:]) { result, scheme in
            result[scheme.name ?? UUID().uuidString] = scheme.map(on: endpoint)
        }
    }
}
