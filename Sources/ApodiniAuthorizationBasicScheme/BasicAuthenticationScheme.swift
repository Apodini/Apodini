//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniAuthorization
import ApodiniHTTPProtocol
import NIOHTTP1
@_implementationOnly import ApodiniOpenAPISecurity

public struct BasicAuthenticationScheme: AuthenticationScheme {
    @Apodini.Environment(\.connection)
    var connection: Connection

    @Throws(.unauthenticated)
    var unauthenticatedError

    public var required = false

    let realm: String
    // The RFC 7617 defines the "charset" parameter, though the only allowed value is "UTF-8", so we leave the configuration out

    // used in the Security Metadata
    public var name: String?
    public var description: String?

    public init(name: String? = nil, realm: String = "Standard Apodini Realm", description: String? = nil) {
        self.name = name
        self.realm = realm
        self.description = description
    }

    public var metadata: Metadata {
        Security(name: name, .http(scheme: "basic"), description: description, required: required)
    }

    public func deriveAuthenticationInfo() throws -> (username: String, password: String)? {
        guard let authorization = connection.information[ApodiniHTTPProtocol.Authorization.self],
              authorization.type.lowercased() == "basic" else {
            return nil
        }

        guard let basic = authorization.basic else {
            // malformed input
            throw mapFailedAuthorization(failedWith: unauthenticatedError)
        }

        return (basic.username, basic.password)
    }

    public func mapFailedAuthorization(failedWith error: ApodiniError) -> ApodiniError {
        error(
            information: WWWAuthenticate(.init(scheme: "Basic", parameters: .init(key: "realm", value: realm))),
            options: .httpResponseStatus(.unauthorized)
        )
    }
}
