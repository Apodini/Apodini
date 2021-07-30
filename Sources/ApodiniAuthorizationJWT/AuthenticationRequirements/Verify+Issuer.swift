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
    init(issuer keyPath: KeyPath<Element, IssuerClaim>, is issuers: String...) where Element: JWTAuthenticatable {
        self.init { element in
            issuers.contains(element[keyPath: keyPath].value)
        }
    }
}
