//
// Created by Andreas Bauer on 15.07.21.
//

import ApodiniAuthorization
import JWTKit

/// The `AuthorizationRequirement` ``VerifyIssuer`` can be used to verify a given
/// `JWTKit.IssuerClaim` of a respective ``JWTAuthenticatable``.
///
/// A `Authorize` Metadata declaration using this requirement might look like the following:
///
/// ```swift
/// var metadata: Metadata {
///     Authorize(SomeJWTToken.self) {
///         VerifyIssuer(\.iss, is: "https://some.issuer.org")
///     }
/// }
/// ```
public struct VerifyIssuer<Element: JWTAuthenticatable>: AuthorizationRequirement {
    private var keyPath: KeyPath<Element, IssuerClaim>
    private var issuers: [String]

    /// Creates a new ``VerifyIssuer`` requirement.
    /// - Parameters:
    ///   - keyPath: The `KeyPath` to the `IssuerClaim` of the ``JWTAuthenticatable``.
    ///   - issuers: Verifies that the issue claim is one of the passed issuers.
    public init(_ keyPath: KeyPath<Element, IssuerClaim>, is issuers: String...) {
        self.keyPath = keyPath
        self.issuers = issuers
    }

    public func evaluate(for element: Element) -> RequirementResult {
        issuers.contains(element[keyPath: keyPath].value)
            ? .undecided(cause: .result(self))
            : .rejected(cause: .error(JWTError.claimVerificationFailure(name: "iss", reason: "Token not provided by \(issuers)")))
    }
}
