//
// Created by Andreas Bauer on 15.07.21.
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
