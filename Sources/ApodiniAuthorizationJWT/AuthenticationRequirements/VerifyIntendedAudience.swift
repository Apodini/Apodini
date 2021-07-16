//
// Created by Andreas Bauer on 15.07.21.
//

import ApodiniAuthorization
import JWTKit

/// The `AuthorizationRequirement` ``VerifyIntendedAudience`` can be used to verify a given
/// `JWTKit.AudienceClaim` of a respective ``JWTAuthenticatable``.
///
/// A `Authorize` Metadata declaration using this requirement might look like the following:
///
/// ```swift
/// var metadata: Metadata {
///     Authorize(SomeJWTToken.self) {
///         VerifyIntendedAudience(\.aud, includes: "expected audience")
///     }
/// }
/// ```
public struct VerifyIntendedAudience<Element: JWTAuthenticatable>: AuthorizationRequirement {
    private var keyPath: KeyPath<Element, AudienceClaim>
    private var audience: String

    /// Creates a new ``VerifyIntendedAudience`` requirement.
    /// - Parameters:
    ///   - keyPath: The `KeyPath` to the `AudienceClaim` of the ``JWTAuthenticatable``.
    ///   - audience: Verifies that the provided audience is contained in the claim.
    public init(_ keyPath: KeyPath<Element, AudienceClaim>, includes audience: String) {
        self.keyPath = keyPath
        self.audience = audience
    }

    public func evaluate(for element: Element) -> RequirementResult {
        do {
            try element[keyPath: keyPath].verifyIntendedAudience(includes: audience)
            return .undecided(cause: .result(self))
        } catch {
            return .rejected(cause: .error(error))
        }
    }
}
