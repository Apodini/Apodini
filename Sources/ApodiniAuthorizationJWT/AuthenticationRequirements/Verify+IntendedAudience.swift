//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
    init(intendedAudience keyPath: KeyPath<Element, AudienceClaim>, includes audience: String) where Element: JWTAuthenticatable {
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
