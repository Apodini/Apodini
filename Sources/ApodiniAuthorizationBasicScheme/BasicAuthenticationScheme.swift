//
// Created by Andreas Bauer on 09.07.21.
//

import Apodini
import ApodiniAuthorization
import ApodiniHTTPProtocol
import NIOHTTP1

public struct BasicAuthenticationScheme: AuthenticationScheme {
    @Apodini.Environment(\.connection)
    var connection: Connection

    @Throws(.unauthenticated)
    var unauthenticatedError

    let realm: String
    // The RFC 7617 defines the "charset" parameter, though the only allowed value is "UTF-8", so we leave the configuration out

    public init(realm: String = "Standard Apodini Realm") {
        self.realm = realm
    }

    public func deriveAuthenticationInfo() throws -> (username: String, password: String)? {
        // TODO does this also contain username@password in url?
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
