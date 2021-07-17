//
// Created by Andreas Bauer on 15.07.21.
//

import ApodiniAuthorization
import JWTKit

public extension Verify {
    /// Creates a new `Verify` `AuthorizationRequirement` that can be used to verify a given
    /// `JWTKit.ExpirationClaim` of a respective ``JWTAuthenticatable``.
    ///
    /// A `Authorize` Metadata declaration using this requirement might look like the following:
    ///
    /// ```swift
    /// var metadata: Metadata {
    ///     Authorize(SomeJWTToken.self) {
    ///         Verify(notExpired: \.exp)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: The `KeyPath` to the `ExpirationClaim` of the ``JWTAuthenticatable``.
    ///   - date: Optionally, provide a different current `Date`. Otherwise **now** is used.
    public init(notExpired keyPath: KeyPath<Element, ExpirationClaim>, date: Date = .init()) where Element: JWTAuthenticatable {
        self.init { element in
            do {
                try element[keyPath: keyPath].verifyNotExpired(currentDate: date)
                return true
            } catch {
                return false
            }
        }
    }
}
