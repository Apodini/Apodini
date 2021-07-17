//
// Created by Andreas Bauer on 11.07.21.
//

import Apodini

/// The ``Authorized`` `DynamicProperty` can be used to access the ``Authenticatable``
/// instance created through a authorization Metadata.
public struct Authorized<Element: Authenticatable>: DynamicProperty {
    @EnvironmentObject
    var environmentValue: AuthorizationStateContainer<Element>

    @Throws(.unauthenticated, options: .authorizationErrorReason(.authenticationRequired))
    var authenticationRequired

    /// Returns if the associated ``Element`` was successfully authenticated.
    /// This property might return false in cases of ``ComponentMetadataNamespace/AuthorizeOptionally`` Metadata.
    public var isAuthorized: Bool {
        environmentValue.element != nil
    }

    public init() {}

    /// Returns the ``Authenticatable`` instance.
    /// - Returns: The ``Authenticatable`` instance.
    /// - Throws: Might throw an `ApodiniError` in cases where an authorized ``Element`` instance
    ///     could not be found.
    public func callAsFunction() throws -> Element {
        guard let element = environmentValue.element else {
            // throws an error because the user requires the Authenticatable to be present, but it isn't.
            // The error is forwarded to the AuthenticationScheme.mapFailedAuthorization(failedWith:).
            // Either use the potentialError created by a `AuthorizeOptionally` Metadata or create a custom one.
            // See docs of `AuthorizationStateContainer/potentialError`
            throw environmentValue.potentialError ?? authenticationRequired
        }

        return element
    }
}
