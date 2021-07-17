//
// Created by Andreas Bauer on 09.07.21.
//

import Apodini

public extension ComponentMetadataNamespace {
    /// Name definition for the ``OptionalAuthorizationComponentMetadata``
    typealias AuthorizeOptionally = OptionalAuthorizationMetadata
}

/// The ``OptionalAuthorizationMetadata`` can be used to add optional authentication and authorization to a ``Component``.
///
/// This Metadata is different to the ``AuthorizationMetadata`` as it won't result in an authentication error
/// if the request doesn't contain any authentication credentials.
///
/// Essential for any ``OptionalAuthorizationMetadata`` is an ``Authenticatable``, a type which captures the state
/// of the authenticated user, token or whatever instance.
///
/// ## Authentication and Authorization
/// Authentication is performed by a predefined ``AuthenticationScheme``, mapping the request input of
/// some sort of wire protocol to a single ``AuthenticationScheme/AuthenticationInfo`` instance, which
/// can be used for further processing.
///
/// An according ``AuthenticationVerifier`` (where `AuthenticationScheme/AuthenticationInfo`` equals
/// ``AuthenticationVerifier/AuthenticationInfo``) is then responsible for turning the AuthenticationInfo
/// into the expected ``Authenticatable`` instance. This might include loading additional information
/// form a database, or simply consist of parsing the input and execution some sort of integrity checks.
///
/// If all those steps succeed, the ``Authenticatable`` instance is evaluated against the provided ``AuthorizationRequirement``s.
///
/// Execution will only be delegated onto the next `Handler` if all those steps above complete successfully,
/// otherwise an appropriate, ``AuthenticationScheme`` defined `ApodiniError` will be returned.
///
/// ## Accessing the authenticated and authorized `Authenticatable` instance
/// Use the ``Authorize`` Apodini `Property` property to access the ``Authenticatable`` instance.
/// See the documentation of the property for an example.
///
/// ## Example
///
/// The Metadata is available under the `ComponentMetadataNamespace/AuthorizeOptionally` name and can be used like the following:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         AuthorizeOptionally(SomeAuthenticatable.self, using: SomeAuthenticationScheme(), verifiedBy: SomeAuthenticationVerifier()) {
///             // ... `AuthorizationRequirement`s are listed here
///         }
///     }
/// }
/// ```
public struct OptionalAuthorizationMetadata: ComponentMetadataDefinition, DefinitionWithDelegatingHandlerKey {
    public let initializer: DelegatingHandlerContextKey.Value

    /// Initializes a new ``OptionalAuthorizationMetadata``.
    /// - Parameters:
    ///   - authenticatable: The ``Authenticatable`` type.
    ///   - authenticationScheme: The ``AuthenticationScheme``.
    ///   - verifier: The respective ``AuthenticationVerifier``. It must both match the ``AuthenticationScheme/AuthenticationInfo``
    ///     as well as the ``Authenticatable`` output type.
    ///   - skipRequirementsForAuthorized: If the Metadata detects, that the `Environment` already contains an
    ///     authenticated and authorized ``Authenticatable`` of the same type, this property controls if the
    ///     ``AuthorizationRequirement`` are nonetheless executed on that instance.
    ///     Default is to not skip the evaluation.
    ///   - requirements: The ``AuthorizationRequirement`` evaluated on the authenticated user.
    public init<Scheme: AuthenticationScheme, Verifier: AuthenticationVerifier, Element>(
        _ authenticatable: Element.Type = Element.self,
        using authenticationScheme: Scheme,
        verifiedBy verifier: Verifier,
        skipRequirementsForAuthorized: Bool = false,
        @AuthorizationRequirementsBuilder<Element> requirements: () -> AuthorizationRequirements<Element> = { AuthorizationRequirements(Allow()) }
    ) where Scheme.AuthenticationInfo == Verifier.AuthenticationInfo, Verifier.Element == Element {
        self.initializer = [
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
