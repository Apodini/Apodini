//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import JWTKit

/// The ``JWTSigner`` `Configuration` can be used to configure `JWTKIT.JWTSigners` for on your Apodini `WebService`.
///
/// Any configured ``JWTSigner`` will be used by the ``JWTVerifier`` when declaring a
/// `ComponentMetadataNamespace/Authorize` or `ComponentMetadataNamespace/AuthorizeOptionally` Metadata.
///
/// The example below configures a `HMAC` with `SHA-512` signer using the key `"secret"`.
/// Refer to https://github.com/vapor/jwt-kit for more information on the available algorithms signers.
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var configuration: Configuration {
///         JWTSigner(.hs512(key: "secret"))
///     }
/// }
/// ```
///
/// The configured signers can then be retrieved from the environment using the `jwtSigners` key.
/// The example below illustrate how one could sign a new JWT Token inside a `Handler`:
/// ```swift
/// struct ExampleHandler: Handler {
///     @Environment(\.jwtSigners)
///     var signers
///
///     func handle() throws -> SomeResponse {
///         let token = ExampleJWTToken(...)
///         let jwt = try signers.sign(token)
///         // ...
///     }
/// }
/// ```
public struct JWTSigner: Configuration {
    private enum JWTSignerType {
        // swiftlint:disable:next discouraged_optional_boolean
        case jwtSigner(_ signer: JWTKit.JWTSigner, kid: JWKIdentifier?, isDefault: Bool?)
        case jwksJSON(_ json: String)
        case jwks(_ jwks: JWKS)
        // swiftlint:disable:next discouraged_optional_boolean
        case jwk(_ jwk: JWK, isDefault: Bool?)
    }

    private let type: JWTSignerType

    /// Configures a new `JWTKit.JWTSigner`.
    /// - Parameters:
    ///   - signer: The `JWTKit.JWTSigner` instance.
    ///   - kid: The optional `JWKIdentifier` identifying the `JWTKit.JWTSigner`.
    ///   - isDefault: Optionally defines if this signer should be considered the default.
    ///     If not defined and no default is yet defined, the signer is considered to be the default.
    public init(_ signer: JWTKit.JWTSigner, kid: JWKIdentifier? = nil, isDefault: Bool? = nil) {
        // swiftlint:disable:previous discouraged_optional_boolean
        self.type = .jwtSigner(signer, kid: kid, isDefault: isDefault)
    }

    /// Configures a `JWKS` (JSON Web Key Set) to this signers collection by first decoding the JSON string.
    /// - Parameter json: The `JWKS` encoded in a json string.
    public init(jwksJSON json: String) {
        self.type = .jwksJSON(json)
    }

    /// Adds a `JWKS` (JSON Web Key Set) to this signers collection.
    /// - Parameter jwks: The `JWKS` instance.
    public init(jwks: JWKS) {
        self.type = .jwks(jwks)
    }

    /// Adds a `JWK` (JSON Web Key) to this signers collection.
    /// - Parameters:
    ///   - jwk: The `JWK` instance.
    ///   - isDefault: Optionally defines if this signer should be considered the default.
    ///     If not defined and no default is yet defined, the signer is considered to be the default.
    public init(jwk: JWK, isDefault: Bool? = nil) {
        // swiftlint:disable:previous discouraged_optional_boolean
        self.type = .jwk(jwk, isDefault: isDefault)
    }

    public func configure(_ app: Application) {
        do {
            switch type {
            case let .jwtSigner(signer, kid, isDefault):
                app.jwtSigners.use(signer, kid: kid, isDefault: isDefault)
            case let .jwksJSON(json):
                try app.jwtSigners.use(jwksJSON: json)
            case let .jwks(jwks):
                try app.jwtSigners.use(jwks: jwks)
            case let .jwk(jwk, isDefault):
                try app.jwtSigners.use(jwk: jwk, isDefault: isDefault)
            }
        } catch {
            fatalError("Failed to configure JWTSigner \(type): \(error)")
        }
    }
}
