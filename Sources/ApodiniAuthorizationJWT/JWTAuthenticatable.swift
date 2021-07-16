//
// Created by Andreas Bauer on 15.07.21.
//

import ApodiniAuthorization
import JWTKit

/// A ``JWTAuthenticatable`` represents a ApodiniAuthorization `Authenticatable` that represents a JSON Web Token.
///
/// See documentation of `JWTKit` and the `JWTPayload` on how to implement a JWT and its claims.
///
/// While you can implement the `verify(using:)` method, it is advised to not do so and express
/// the verification claims using `AuthorizationRequirement`s.
/// The `ApodiniAuthorizationJWT` package provides the following `AuthorizationRequirement`s to verify JWT claims:
/// - ``VerifyIntendedAudience``
/// - ``VerifyIssuer``
/// - ``VerifyNotBefore``
/// - ``VerifyNotExpired``
public protocol JWTAuthenticatable: Authenticatable, JWTPayload {}

public extension JWTAuthenticatable {
    /// Empty default implementation. See docs of ``JWTAuthenticatable``.
    func verify(using signer: JWTKit.JWTSigner) throws {}
}
