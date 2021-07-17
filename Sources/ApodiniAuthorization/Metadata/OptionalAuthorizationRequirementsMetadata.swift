//
// Created by Andreas Bauer on 16.07.21.
//

import Apodini

public extension ComponentMetadataNamespace {
    /// Name definition for the ``OptionalAuthorizationRequirementsMetadata``
    typealias OptionalAuthorizationRequirements = OptionalAuthorizationRequirementsMetadata
}

// swiftlint:disable:next type_name
public struct OptionalAuthorizationRequirementsMetadata<Element: Authenticatable>: ComponentMetadataDefinition, DefinitionWithDelegatingHandlerKey {
    public let initializer: DelegatingHandlerContextKey.Value

    public init(
        _ authenticatable: Element.Type = Element.self,
        @AuthorizationRequirementsBuilder<Element> requirements: () -> AuthorizationRequirements<Element>
    ) {
        self.initializer = [
            .init(AuthorizationRequirementsCheckerInitializer(type: .optional, requirements: requirements()))
        ]
    }
}
