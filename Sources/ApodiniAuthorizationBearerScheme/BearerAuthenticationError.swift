//
// Created by Andreas Bauer on 16.07.21.
//

import Apodini

/// Represents additional information for the ``BearerAuthenticationScheme`` for `ApodiniError`s
/// created due to some sort of authentication or authorization error.
///
/// ## Setting the option
/// ```swift
/// @Throws(.unauthenticated, options: .bearerErrorResponse(.init(...))
/// var unauthenticatedError
/// ```
public struct BearerAuthenticationError: ApodiniErrorCompliantOption {
    let error: BearerErrorCode?
    let description: String?
    let uri: String?

    /// Initializes a new ``BearerAuthenticationError``.
    /// - Parameters:
    ///   - error: The
    ///   - description:
    ///   - uri:
    public init(_ error: BearerErrorCode? = nil, description: String? = nil, uri: String? = nil) {
        self.error = error
        self.description = description
        self.uri = uri
    }

    public static func `default`(for type: ErrorType) -> BearerAuthenticationError {
        BearerAuthenticationError()
    }
}

extension PropertyOptionKey where PropertyNameSpace == ErrorOptionNameSpace, Option == BearerAuthenticationError {
    /// The ``PropertyOptionKey`` for ``BearerAuthenticationError`` of an ``ApodiniError``.
    static let bearerError = PropertyOptionKey<ErrorOptionNameSpace, BearerAuthenticationError>()
}

public extension AnyPropertyOption where PropertyNameSpace == ErrorOptionNameSpace {
    /// An `ApodiniError` option that holds the ``BearerAuthenticationError``.
    static func bearerErrorResponse(_ error: BearerAuthenticationError) -> AnyPropertyOption<ErrorOptionNameSpace> {
        AnyPropertyOption(key: .bearerError, value: error)
    }
}
