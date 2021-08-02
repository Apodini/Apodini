//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniAuthorization
import JWTKit

/// A ``JWTAuthenticatable`` represents a ApodiniAuthorization `Authenticatable` that represents a JSON Web Token.
///
/// See documentation of `JWTKit` and the `JWTPayload` on how to implement a JWT and its claims.
///
/// While you can implement the `verify(using:)` method, it is advised to not do so and express
/// the verification claims using `AuthorizationRequirement`s.
/// The `ApodiniAuthorizationJWT` package provides the following extension to the `Verify` `AuthorizationRequirement`,
//  in order to easily verify JWT claims:
/// - ``Verify/init(intendedAudience:includes:)``
/// - ``Verify/init(issuer:is:)``
/// - ``Verify/init(notBefore:date:)``
/// - ``Verify/init(notExpired:date:)``
public protocol JWTAuthenticatable: Authenticatable, JWTPayload {}

public extension JWTAuthenticatable {
    /// Empty default implementation. See docs of ``JWTAuthenticatable``.
    func verify(using signer: JWTKit.JWTSigner) throws {}
}
