//
// Created by Andreas Bauer on 29.08.21.
//

import Apodini

public extension TypedContentMetadataNamespace {
    typealias MaxLength = StringMaxLengthMetadata<Self>
}

public extension ContentMetadataNamespace {
    typealias MaxLength<Element: Content> = StringMaxLengthMetadata<Element>
}

public struct StringMaxLengthMetadata<Element: Content>: ContentMetadataDefinition {
    public typealias Key = OpenAPIJSONSchemeModificationContextKey

    public let value: [JSONSchemeModificationType]

    public init(of property: KeyPath<Element, String>, is length: Int, propertyName: String) {
        self.value = [
            .property(property: propertyName, modification: PropertyModification(
                context: StringContext.self,
                property: .maxLength,
                value: length
            ))
        ]
    }
}
