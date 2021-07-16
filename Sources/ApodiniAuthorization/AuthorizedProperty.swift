//
// Created by Andreas Bauer on 11.07.21.
//

import Apodini

public struct Authorized<Element: Authenticatable>: DynamicProperty {
    @EnvironmentObject
    var environmentValue: AuthorizationStateContainer<Element>

    @Throws(.unauthenticated, options: .authorizationErrorReason(.authenticationRequired))
    var authenticationRequired

    var isAuthorized: Bool {
        environmentValue.element != nil
    }

    public init() {}

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
