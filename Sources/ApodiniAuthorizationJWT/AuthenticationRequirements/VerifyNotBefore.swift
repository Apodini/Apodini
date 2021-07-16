//
// Created by Andreas Bauer on 15.07.21.
//

import ApodiniAuthorization
import JWTKit

/// The `AuthorizationRequirement` ``VerifyNotBefore`` can be used to verify a given
/// `JWTKit.NotBeforeClaim` of a respective ``JWTAuthenticatable``.
///
/// A `Authorize` Metadata declaration using this requirement might look like the following:
///
/// ```swift
/// var metadata: Metadata {
///     Authorize(SomeJWTToken.self) {
///         VerifyNotBefore(\.nbf)
///     }
/// }
/// ```
public struct VerifyNotBefore<Element: JWTAuthenticatable>: AuthorizationRequirement {
    private var keyPath: KeyPath<Element, NotBeforeClaim>
    private var date: Date

    /// Creates a new ``VerifyNotBefore`` requirement.
    /// - Parameters:
    ///   - keyPath: The `KeyPath` to the `NotBeforeClaim` of the ``JWTAuthenticatable``.
    ///   - date: Optionally, provide a different current `Date`. Otherwise **now** is used.
    public init(_ keyPath: KeyPath<Element, NotBeforeClaim>, date: Date = .init()) {
        self.keyPath = keyPath
        self.date = date
    }

    public func evaluate(for element: Element) -> RequirementResult {
        do {
            try element[keyPath: keyPath].verifyNotBefore(currentDate: date)
            return .undecided(cause: .result(self))
        } catch {
            return .rejected(cause: .error(error))
        }
    }
}
