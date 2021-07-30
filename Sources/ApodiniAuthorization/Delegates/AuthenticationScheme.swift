//
// Created by Andreas Bauer on 03.07.21.
//

import Apodini

/// An ``AuthenticationScheme`` represents an application domain defined authentication scheme.
/// The purpose of an ``AuthenticationScheme`` is to transform the application domain specific wire format
/// into a generic reusable, verified and machine readable format, the ``AuthenticationScheme/AuthenticationInfo``.
/// An ``AuthenticationVerifier`` would then operate on the result of an ``AuthenticationScheme`` to initialize
/// the ``Authenticatable`` instance and verify its correctness and/or integrity.
///
/// In an ``AuthenticationScheme`` you can use any common ``Property`` similar as you can in a  ``Handler``.
public protocol AuthenticationScheme {
    /// The result type of an ``AuthenticationScheme``.
    associatedtype AuthenticationInfo

    /// This method derives the ``AuthenticationInfo`` from the request input.
    /// What and how that request input is transformed is completely application domain defined.
    ///
    /// If the request does not contain any authentication input the method MUST return `nil` to signal non-existence.
    /// If the input contains authentication input, but in an malformed way an according `ApodiniError` must be thrown.
    ///
    /// - Returns: The parsed ``AuthenticationInfo`` instance.
    /// - Throws: Throws an `ApodiniError` if encountering malformed input.
    ///     Any error thrown by this method will always be feed into `mapFailedAuthorization(failedWith:)`.
    func deriveAuthenticationInfo() throws -> AuthenticationInfo?

    /// This method is used to map an generic `ApodiniError` encountered in the authentication and authorization process
    /// to a `ApodiniError` instance which potentially contains ``AuthenticationScheme`` specific options or `Information`s.
    ///
    /// For example, a respective ``AuthenticationScheme`` might use this method to include a new
    /// authentication challenge in the response on every failed authentication attempt.
    ///
    /// Every `ApodiniError` passed to this method will contain the according ``AuthorizationErrorReason``
    /// in the error options. It can be queried like the following:
    /// ```swift
    /// let reason = apodiniError..option(for: .authorizationErrorReason)
    /// ```
    ///
    /// An ``AuthenticationScheme`` might also define custom `ApodiniError` options which can be parsed here,
    /// in order to support wire format specific features. An error containing such custom error options
    /// might be thrown inside a custom ``AuthenticationVerifier`` implementation, or inside a ``AuthorizationRequirement``,
    /// or anywhere else in the `Handler` stack, if it includes the ``AuthorizationErrorReason`` option.
    ///
    /// - Parameter error: The thrown `ApodiniError` which contains a ``AuthorizationErrorReason`` option.
    /// - Returns: Returns the MODIFIED `ApodiniError` (according to the wire format).
    ///     The method MUST NOT create a new instance, as it would erase any custom defined options or Information instances.
    func mapFailedAuthorization(failedWith error: ApodiniError) -> ApodiniError
}

public extension AuthenticationScheme {
    /// Default implementation which just forwards the `ApodiniError` without modifying it.
    func mapFailedAuthorization(failedWith error: ApodiniError) -> ApodiniError {
        error
    }
}
