//
// Created by Andreas Bauer on 28.08.21.
//

import Apodini

public extension TypedContentMetadataNamespace {
    typealias MarkDeprecated = DeprecationMarkMetadata<Self>
}

public extension ContentMetadataNamespace {
    typealias MarkDeprecated<Element: Content> = DeprecationMarkMetadata<Element>
}

public struct DeprecationMarkMetadata<Element: Content>: ContentMetadataDefinition {
    public typealias Key = OpenAPIJSONSchemeModificationContextKey

    public let value: [JSONSchemeModificationType]

    public init (_ deprecation: Bool = true) {
        value = [.root(modification: PropertyModification(
            context: CoreContext.self,
            property: .deprecated,
            value: deprecation
        ))]
    }

    public init<Value>(property _: KeyPath<Element, Value>, _ deprecation: Bool = true, propertyName: String) {
        value = [.property(property: propertyName, modification: PropertyModification(
            context: CoreContext.self,
            property: .deprecated,
            value: deprecation
        ))]
    }
}
