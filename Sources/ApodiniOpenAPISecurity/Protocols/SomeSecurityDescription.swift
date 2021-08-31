//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// Describes a single security description of an endpoint.
public protocol SomeSecurityDescription {
    /// The associated type of the ``OpenAPISecurityScheme``.
    associatedtype SecurityScheme: OpenAPISecurityScheme

    /// The security scheme.
    var scheme: SecurityScheme { get }
    /// Defines if the security requirement is required.
    var required: Bool { get }
    /// Defines, if applicable, the requires scopes of the oauth based security requirement.
    var scopes: [String] { get }

    /// Initializes a new ``SomeSecurityDescription``.
    init(scheme: SecurityScheme, required: Bool, scopes: [String])
}
