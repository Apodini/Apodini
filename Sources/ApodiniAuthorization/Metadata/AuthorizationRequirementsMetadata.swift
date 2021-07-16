//
// Created by Andreas Bauer on 16.07.21.
//

import Apodini

public extension ComponentMetadataNamespace {
    /// Name definition for the ``AuthorizationRequirementsMetadata``
    typealias AuthorizationRequirements = AuthorizationRequirementsMetadata
}

public struct AuthorizationRequirementsMetadata<Element: Authenticatable>: ComponentMetadataDefinition, DefinitionWithDelegatingHandlerKey {
    public let initializer: DelegatingHandlerContextKey.Value

    public init(@AuthorizationRequirementsBuilder<Element> requirements: () -> AuthorizationRequirements<Element>) {
        self.initializer = [
            .init(AuthorizationRequirementsCheckerInitializer(type: .required, requirements: requirements()))
        ]
    }
}
