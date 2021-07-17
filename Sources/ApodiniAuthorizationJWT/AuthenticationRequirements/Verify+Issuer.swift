//
// Created by Andreas Bauer on 15.07.21.
//

import ApodiniAuthorization
import JWTKit

public extension Verify {
    /// Creates a new `Verify` `AuthorizationRequirement` that can be used to verify a given
    /// `JWTKit.IssuerClaim` of a respective ``JWTAuthenticatable``.
    ///
    /// A `Authorize` Metadata declaration using this requirement might look like the following:
    ///
    /// ```swift
    /// var metadata: Metadata {
    ///     Authorize(SomeJWTToken.self) {
    ///         Verify(issuer: \.iss, is: "https://some.issuer.org", "https://some-other.issuer.org")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: The `KeyPath` to the `IssuerClaim` of the ``JWTAuthenticatable``.
    ///   - issuers: Verifies that the issue claim is one of the passed issuers.
    init(issuer keyPath: KeyPath<Element, IssuerClaim>, is issuers: String...) {
        self.init { element in
            issuers.contains(element[keyPath: keyPath].value)
        }
    }
}
