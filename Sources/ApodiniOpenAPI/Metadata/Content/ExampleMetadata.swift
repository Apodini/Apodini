//
// Created by Andreas Bauer on 28.08.21.
//

import Apodini
import OpenAPIKit

public extension TypedContentMetadataNamespace {
    typealias Example = ExampleMetadata<Self>
}

public extension ContentMetadataNamespace {
    typealias Example<Element: Content> = ExampleMetadata<Element>
}

public struct ExampleMetadata<Element: Content>: ContentMetadataDefinition {
    public typealias Key = OpenAPIJSONSchemeModificationContextKey

    public let value: [JSONSchemeModificationType]

    // TODO generify the Metadata to provide default args!
    public init(_ example: Element) {
        value = [.root(modification: PropertyModification(
            context: CoreContext.self,
            property: .example,
            value: AnyCodable.fromComplex(example)
        ))]
    }

    // TODO propertyName is required for now!
    public init<Value: Encodable>(for _: KeyPath<Element, Value>, _ example: Value, propertyName: String) {
        value = [.property(property: propertyName, modification: PropertyModification(
            context: CoreContext.self,
            property: .example,
            value: AnyCodable.fromComplex(example)
        ))]
    }
}