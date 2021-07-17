//
// Created by Andreas Bauer on 15.07.21.
//

import ApodiniAuthorization
import JWTKit

public extension Verify {
    /// Creates a new `Verify` `AuthorizationRequirement` that can be used to verify a given
    /// `JWTKit.AudienceClaim` of a respective ``JWTAuthenticatable``.
    ///
    /// A `Authorize` Metadata declaration using this requirement might look like the following:
    ///
    /// ```swift
    /// var metadata: Metadata {
    ///     Authorize(SomeJWTToken.self) {
    ///         Verify(intendedAudience: \.aud, includes: "expected-audience")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: The `KeyPath` to the `AudienceClaim` of the ``JWTAuthenticatable``.
    ///   - audience: Verifies that the provided audience is contained in the claim.
    init(intendedAudience keyPath: KeyPath<Element, AudienceClaim>, includes audience: String) {
        self.init { element in
            do {
                try element[keyPath: keyPath].verifyIntendedAudience(includes: audience)
                return true
            } catch {
                return false
            }
        }
    }
}
