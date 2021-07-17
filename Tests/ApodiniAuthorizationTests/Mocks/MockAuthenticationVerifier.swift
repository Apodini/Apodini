//
// Created by Andreas Bauer on 17.07.21.
//

import Foundation
import Apodini
import ApodiniAuthorization
import ApodiniAuthorizationBearerScheme

struct MockCredentialVerifier<State>: AuthenticationVerifier {
    let expectedPassword: String
    let state: State

    @Throws(.unauthenticated)
    var unauthenticatedError

    func initializeAndVerify(for authenticationInfo: (username: String, password: String)) throws -> MockCredentials<State> {
        let instance = MockCredentials(
            username: authenticationInfo.username,
            password: authenticationInfo.password,
            email: "test@example.de",
            state: state
        )

        if expectedPassword != instance.password {
            throw unauthenticatedError
        }

        return instance
    }
}

struct MockJsonTokenVerifier<Element: Authenticatable>: AuthenticationVerifier where Element: Codable {
    @Throws(.unauthenticated)
    var unauthenticatedError

    func initializeAndVerify(for authenticationInfo: String) throws -> Element {
        let decoder = JSONDecoder()
        return try decoder.decode(Element.self, from: authenticationInfo.data(using: .utf8)!)
    }
}
