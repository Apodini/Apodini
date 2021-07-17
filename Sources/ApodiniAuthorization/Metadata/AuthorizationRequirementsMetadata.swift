//
// Created by Andreas Bauer on 16.07.21.
//

import Apodini

public extension ComponentMetadataNamespace {
    /// Name definition for the ``AuthorizationRequirementsMetadata``
    typealias AuthorizationRequirements = AuthorizationRequirementsMetadata
}

/// The ``AuthorizationRequirementsMetadata`` can be used to execute additional ``AuthorizationRequirement``s
/// for a dedicated ``Authenticatable`` instance which was already authenticated and authorized by a 
/// previously defined ``AuthorizationMetadata`` or ``OptionalAuthorizationMetadata``.
///
/// A according `ApodiniError` will be thrown if no such authorized ``Authenticatable`` instance
/// can be found in the `Environment`.
///
/// The Metadata is available under the `ComponentMetadataNamespace/AuthorizationRequirements` name and can be used like the following:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         AuthorizationRequirements(SomeAuthenticatable.self) {
///             // ... `AuthorizationRequirement`s are listed here
///         }
///     }
/// }
/// ```
public struct AuthorizationRequirementsMetadata<Element: Authenticatable>: ComponentMetadataDefinition, DefinitionWithDelegatingHandlerKey {
    public let initializer: DelegatingHandlerContextKey.Value

    /// Initializes a new ``AuthorizationRequirementsMetadata``.
    /// - Parameters:
    ///   - authenticatable: The ``Authenticatable`` type.
    ///   - requirements: The ``AuthorizationRequirement`` evaluated on the authenticated user.
    public init(
        _ authenticatable: Element.Type = Element.self,
        @AuthorizationRequirementsBuilder<Element> requirements: () -> AuthorizationRequirements<Element>
    ) {
        self.initializer = [
            .init(AuthorizationRequirementsCheckerInitializer(type: .required, requirements: requirements()))
        ]
    }
}
