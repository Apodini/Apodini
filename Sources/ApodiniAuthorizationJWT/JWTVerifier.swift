//
// Created by Andreas Bauer on 15.07.21.
//

import Apodini
import ApodiniAuthorization
import JWTKit

/// The ``JWTVerifier`` implements an Apodini ``AuthenticationVerifier`` expecting a
/// `AuthenticationInfo` of type `String`, holding the Json Web Token.
/// The ``JWTVerifier`` is best used with the `BearerAuthenticationScheme`, but can be used
/// with any other `AuthenticationScheme` creating a string based AuthenticationInfo.
///
/// The ``JWTVerifier`` instantiates the provided ``JWTAuthenticatable`` and verifies its signature
/// using the `JWTKit.JWTSigners` configured via the ``JWTSigner`` configuration.
public struct JWTVerifier<Element: JWTAuthenticatable>: AuthenticationVerifier {
    @Environment(\.jwtSigners)
    var signers
    
    public init() {}

    public func initializeAndVerify(for authenticationInfo: String) throws -> Element {
        try signers.verify(authenticationInfo, as: Element.self)
    }
}
