//
// Created by Andreas Bauer on 16.07.21.
//

import Apodini

/// The ``AuthorizationErrorReason`` of any `ApodiniError` encountered in the process of authentication or authorization.
/// Any `ApodiniError` containing the respective ``AuthorizationErrorReason`` option will be forwarded to the
/// ``AuthenticationScheme`` to be completed with wire-format-specific information and options.
public enum AuthorizationErrorReason: PropertyOption, Equatable {
    /// No authentication information was specified but was required.
    case authenticationRequired
    /// Encountered malformed or invalid authentication information (error thrown inside ``AuthenticationScheme``)
    case invalidAuthenticationRequest
    /// Failed the authentication (error thrown inside ``AuthenticationVerifier``)
    case failedAuthentication
    /// The ``Authenticatable`` instance failed evaluation against the ``AuthorizationRequirement``s
    case failedAuthorization
    /// Represents some custom, potentially user defined error reason, to be used if the others don't fit.
    /// A string based reason shall be supplied for debugging uses.
    case custom(_ reason: String)
}

extension PropertyOptionKey where PropertyNameSpace == ErrorOptionNameSpace, Option == AuthorizationErrorReason {
    /// The ``PropertyOptionKey`` for ``AuthorizationErrorReason`` of an ``ApodiniError``.
    public static let authorizationErrorReason = PropertyOptionKey<ErrorOptionNameSpace, AuthorizationErrorReason>()
}

public extension AnyPropertyOption where PropertyNameSpace == ErrorOptionNameSpace {
    /// An `ApodiniError` option that holds the ``AuthorizationErrorReason``.
    static func authorizationErrorReason(_ reason: AuthorizationErrorReason) -> AnyPropertyOption<ErrorOptionNameSpace> {
        AnyPropertyOption(key: .authorizationErrorReason, value: reason)
    }
}
