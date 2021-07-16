//
// Created by Andreas Bauer on 15.07.21.
//

import ApodiniAuthorization
import ApodiniAuthorizationBearerScheme

public extension AuthorizationMetadata {
    /// Initializes a new `AuthorizationMetadata` using the `BearerAuthenticationScheme` and the ``JWTVerifier``.
    /// - Parameters:
    ///   - authenticatable: The ``JWTAuthenticatable``
    ///   - requirements: TODO finish docs
    init<Element: JWTAuthenticatable>(
        _ authenticatable: Element.Type = Element.self,
        @AuthorizationRequirementsBuilder<Element> requirements: () -> AuthorizationRequirements<Element> = { AuthorizationRequirements(Allow()) }
    ) {
        // TODO doesn't allow to configure the bearer auth scheme!
        self.init(authenticatable, using: BearerAuthenticationScheme(), verifiedBy: JWTVerifier(), requirements: requirements)
    }

    init<Scheme: AuthenticationScheme, Element: JWTAuthenticatable>(
        _ authenticatable: Element.Type = Element.self,
        using authenticationScheme: Scheme,
        @AuthorizationRequirementsBuilder<Element> requirements: () -> AuthorizationRequirements<Element> = { AuthorizationRequirements(Allow()) }
    ) where Scheme.AuthenticationInfo == String {
        self.init(authenticatable, using: authenticationScheme, verifiedBy: JWTVerifier(), requirements: requirements)
    }
}
