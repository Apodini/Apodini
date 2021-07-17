//
// Created by Andreas Bauer on 16.07.21.
//

import Apodini

public extension ComponentMetadataNamespace {
    /// Name definition for the ``OptionalAuthorizationRequirementsMetadata``
    typealias OptionalAuthorizationRequirements = OptionalAuthorizationRequirementsMetadata
}

/// The ``OptionalAuthorizationRequirementsMetadata`` can be used to execute additional ``AuthorizationRequirement``s
/// for a dedicated ``Authenticatable`` instance which was already authenticated and authorized by a
/// previously defined ``AuthorizationMetadata`` or ``OptionalAuthorizationMetadata``.
///
/// The check is optional, it won't be executed if the no such authorized ``Authenticatable`` instance
/// can be found in the `Environment`.
///
/// The Metadata is available under the `ComponentMetadataNamespace/OptionalAuthorizationRequirements` name and can be used like the following:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         OptionalAuthorizationRequirements(SomeAuthenticatable.self) {
///             // ... `AuthorizationRequirement`s are listed here
///         }
///     }
/// }
/// ```
public struct OptionalAuthorizationRequirementsMetadata<Element: Authenticatable>: ComponentMetadataDefinition, DefinitionWithDelegatingHandlerKey {
    // swiftlint:disable:previous type_name
    public let initializer: DelegatingHandlerContextKey.Value

    /// Initializes a new ``OptionalAuthorizationRequirementsMetadata``.
    /// - Parameters:
    ///   - authenticatable: The ``Authenticatable`` type.
    ///   - requirements: The ``AuthorizationRequirement`` evaluated on the authenticated user.
    public init(
        _ authenticatable: Element.Type = Element.self,
        @AuthorizationRequirementsBuilder<Element> requirements: () -> AuthorizationRequirements<Element>
    ) {
        self.initializer = [
            .init(AuthorizationRequirementsCheckerInitializer(type: .optional, requirements: requirements()))
        ]
    }
}
