//
// Created by Andreas Bauer on 09.07.21.
//

import Apodini
import ApodiniAuthorization
import ApodiniHTTPProtocol

/// The ``BearerAuthenticationScheme`` implements a Apodini `AuthenticationScheme` parsing the bearer authorization information.
/// See RFC 6750 for more details on the Bearer token scheme.
///
/// You might use the ``BearerAuthenticationError`` and its respective `ApodiniError` option to customize
/// the returned authentication challenge.
public struct BearerAuthenticationScheme: AuthenticationScheme {
    @Apodini.Environment(\.connection)
    var connection: Connection

    @Throws(.unauthenticated)
    var unauthenticatedError: ApodiniError

    let realm: String?
    let scope: [String]

    public init(realm: String? = nil, scope: [String] = []) {
        self.realm = realm
        self.scope = scope
    }

    public func deriveAuthenticationInfo() throws -> String? {
        guard let authorization = connection.information[ApodiniHTTPProtocol.Authorization.self],
              authorization.type.lowercased() == "bearer" else {
            // no authentication information present
            return nil
        }

        guard let bearerToken = authorization.bearerToken else {
            // bearer token was specified but failed parsing (won't actually happen)
            throw unauthenticatedError(options: .bearerErrorResponse(.init(.invalidRequest)))
        }

        return bearerToken
    }

    public func mapFailedAuthorization(failedWith error: ApodiniError) -> ApodiniError {
        let errorResponse = error.option(for: .bearerError)

        var parameters: [WWWAuthenticate.AuthenticationParameter] = []

        if let realm = realm {
            parameters.append(.init(key: "realm", value: realm))
        }
        if !scope.isEmpty {
            parameters.append(.init(key: "scope", value: scope.joined(separator: " ")))
        }

        if let errorCode = errorResponse.error {
            parameters.append(.init(key: "error", value: errorCode.rawValue))
        }
        if let description = errorResponse.description {
            parameters.append(.init(key: "error_description", value: description))
        }
        if let uri = errorResponse.uri {
            parameters.append(.init(key: "error_uri", value: uri))
        }

        let information = WWWAuthenticate(.init(
            scheme: "Bearer",
            parameters: parameters)
        )

        if let bearerError = errorResponse.error {
            if error.option(for: .httpResponseStatus) != nil {
                return error(information: information)
            } else {
                return error(information: information, options: .httpResponseStatus(bearerError.advisedStatusCode))
            }
        } else {
            return error(information: information, options: .httpResponseStatus(.unauthorized))
        }
    }
}
