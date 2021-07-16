//
// Created by Andreas Bauer on 15.07.21.
//

import ApodiniAuthorization
import JWTKit

/// The `AuthorizationRequirement` ``VerifyNotExpired`` can be used to verify a given
/// `JWTKit.ExpirationClaim` of a respective ``JWTAuthenticatable``.
///
/// A `Authorize` Metadata declaration using this requirement might look like the following:
///
/// ```swift
/// var metadata: Metadata {
///     Authorize(SomeJWTToken.self) {
///         VerifyNotExpired(\.exp)
///     }
/// }
/// ```
public struct VerifyNotExpired<Element: JWTAuthenticatable>: AuthorizationRequirement {
    private var keyPath: KeyPath<Element, ExpirationClaim>
    private var date: Date

    /// Creates a new ``VerifyNotExpired`` requirement.
    /// - Parameters:
    ///   - keyPath: The `KeyPath` to the `ExpirationClaim` of the ``JWTAuthenticatable``.
    ///   - date: Optionally, provide a different current `Date`. Otherwise **now** is used.
    public init(_ keyPath: KeyPath<Element, ExpirationClaim>, date: Date = .init()) {
        self.keyPath = keyPath
        self.date = date
    }

    public func evaluate(for element: Element) -> RequirementResult {
        do {
            try element[keyPath: keyPath].verifyNotExpired(currentDate: date)
            return .undecided(cause: .result(self))
        } catch {
            return .rejected(cause: .error(error))
        }
    }
}
