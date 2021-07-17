//
// Created by Andreas Bauer on 09.07.21.
//

import Apodini

public extension ComponentMetadataNamespace {
    /// Name definition for the ``OptionalAuthorizationComponentMetadata``
    typealias AuthorizeOptionally = OptionalAuthorizationMetadata
}

public struct OptionalAuthorizationMetadata: ComponentMetadataDefinition, DefinitionWithDelegatingHandlerKey {
    public let initializer: DelegatingHandlerContextKey.Value

    public init<Scheme: AuthenticationScheme, Verifier: AuthenticationVerifier, Element>(
        _ authenticatable: Element.Type = Element.self,
        using authenticationScheme: Scheme,
        verifiedBy verifier: Verifier,
        skipRequirementsForAuthorized: Bool = false,
        @AuthorizationRequirementsBuilder<Element> requirements: () -> AuthorizationRequirements<Element> = { AuthorizationRequirements(Allow()) }
    ) where Scheme.AuthenticationInfo == Verifier.AuthenticationInfo, Verifier.Element == Element {
        self.initializer = [
            .init(AuthenticationEnvironmentInjectorInitializer<Element>(), ensureInitializerTypeUniqueness: true),
            .init(AuthenticatorInitializer(
                StandardAuthenticatorConfiguration(
                    type: .optional,
                    scheme: authenticationScheme,
                    verifier: verifier,
                    authenticatable: authenticatable,
                    skipRequirementsForAuthorized: skipRequirementsForAuthorized
                ),
                requirements()
            ))
        ]
    }
}
