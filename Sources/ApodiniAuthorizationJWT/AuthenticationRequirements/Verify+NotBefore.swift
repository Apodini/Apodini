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
    /// `JWTKit.NotBeforeClaim` of a respective ``JWTAuthenticatable``.
    ///
    /// A `Authorize` Metadata declaration using this requirement might look like the following:
    ///
    /// ```swift
    /// var metadata: Metadata {
    ///     Authorize(SomeJWTToken.self) {
    ///         Verify(notBefore: \.nbf)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: The `KeyPath` to the `NotBeforeClaim` of the ``JWTAuthenticatable``.
    ///   - date: Optionally, provide a different current `Date`. Otherwise **now** is used.
    init(notBefore keyPath: KeyPath<Element, NotBeforeClaim>, date: Date = .init()) where Element: JWTAuthenticatable {
        self.init { element in
            do {
                try element[keyPath: keyPath].verifyNotBefore(currentDate: date)
                return true
            } catch {
                return false
            }
        }
    }
}
