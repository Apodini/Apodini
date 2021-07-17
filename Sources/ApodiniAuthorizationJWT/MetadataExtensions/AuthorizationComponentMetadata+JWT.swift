//
// Created by Andreas Bauer on 15.07.21.
//

import ApodiniAuthorization
import ApodiniAuthorizationBearerScheme

public extension AuthorizationMetadata {
    /// Initializes a new `AuthorizationMetadata` using the `BearerAuthenticationScheme` and the ``JWTVerifier``.
    /// - Parameters:
    ///   - authenticatable: The ``JWTAuthenticatable``.
    ///   - requirements: The ``AuthorizationRequirement`` evaluated on the authenticated token.
    init<Element: JWTAuthenticatable>(
        _ authenticatable: Element.Type = Element.self,
        skipRequirementsForAuthorized: Bool = false,
        @AuthorizationRequirementsBuilder<Element> requirements: () -> AuthorizationRequirements<Element> = { AuthorizationRequirements(Allow()) }
    ) {
        self.init(
            authenticatable,
            using: BearerAuthenticationScheme(),
            skipRequirementsForAuthorized: skipRequirementsForAuthorized,
            requirements: requirements
        )
    }

    /// Initializes a new `AuthorizationMetadata` using the `BearerAuthenticationScheme` and the ``JWTVerifier``.
    /// This initializer is particularly useful to pass a custom `AuthenticationScheme` or to pass
    /// a `BearerAuthenticationScheme` with custom configuration.
    /// - Parameters:
    ///   - authenticatable: The ``JWTAuthenticatable``.
    ///   - requirements: The ``AuthorizationRequirement`` evaluated on the authenticated token.
    init<Scheme: AuthenticationScheme, Element: JWTAuthenticatable>(
        _ authenticatable: Element.Type = Element.self,
        using authenticationScheme: Scheme,
        skipRequirementsForAuthorized: Bool = false,
        @AuthorizationRequirementsBuilder<Element> requirements: () -> AuthorizationRequirements<Element> = { AuthorizationRequirements(Allow()) }
    ) where Scheme.AuthenticationInfo == String {
        self.init(
            authenticatable,
            using: authenticationScheme,
            verifiedBy: JWTVerifier(),
            skipRequirementsForAuthorized: skipRequirementsForAuthorized,
            requirements: requirements
        )
    }
}
