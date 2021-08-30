//
// Created by Andreas Bauer on 29.08.21.
//

import Apodini

public extension TypedContentMetadataNamespace {
    typealias MinLength = StringMinLengthMetadata<Self>
}

public extension ContentMetadataNamespace {
    typealias MinLength<Element: Content> = StringMinLengthMetadata<Element>
}

public struct StringMinLengthMetadata<Element: Content>: ContentMetadataDefinition {
    public typealias Key = OpenAPIJSONSchemeModificationContextKey

    public let value: [JSONSchemeModificationType]

    public init(of property: KeyPath<Element, String>, is length: Int, propertyName: String) {
        self.value = [
            .property(property: propertyName, modification: PropertyModification(
                context: StringContext.self,
                property: .minLength,
                value: length
            ))
        ]
    }
}
