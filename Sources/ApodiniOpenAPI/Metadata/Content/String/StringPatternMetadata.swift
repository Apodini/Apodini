//
// Created by Andreas Bauer on 29.08.21.
//

import Apodini

public extension TypedContentMetadataNamespace {
    typealias Pattern = StringPatternMetadata<Self>
}

public extension ContentMetadataNamespace {
    typealias Pattern<Element: Content> = StringPatternMetadata<Element>
}

public struct StringPatternMetadata<Element: Content>: ContentMetadataDefinition {
    public typealias Key = OpenAPIJSONSchemeModificationContextKey

    public let value: [JSONSchemeModificationType]

    public init(of property: KeyPath<Element, String>, is pattern: String, propertyName: String) {
        self.value = [
            .property(property: propertyName, modification: PropertyModification(
                context: StringContext.self,
                property: .pattern,
                value: pattern
            ))
        ]
    }
}
