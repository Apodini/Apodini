//
// Created by Andreas Bauer on 29.08.21.
//

import Apodini
import OpenAPIKit

public extension TypedContentMetadataNamespace {
    typealias Maximum = NumericMaximumMetadata<Self>
}

public extension ContentMetadataNamespace {
    typealias Maximum<Element: Content> = NumericMaximumMetadata<Element>
}

public struct NumericMaximumMetadata<Element: Content>: ContentMetadataDefinition {
    public typealias Key = OpenAPIJSONSchemeModificationContextKey

    public let value: [JSONSchemeModificationType]

    /// Initializer for Integer MultipleOf
    private init(value: Int, exclusive: Bool, propertyName: String) {
        self.value = [
            .property(property: propertyName, modification: PropertyModification(
                context: IntegerContext.self,
                property: .maximum,
                value: (value, exclusive: exclusive)
            ))
        ]
    }

    /// Initializer for Integer MultipleOf
    private init(value: Double, exclusive: Bool, propertyName: String) {
        self.value = [
            .property(property: propertyName, modification: PropertyModification(
                context: NumericContext.self,
                property: .maximum,
                value: (value, exclusive: exclusive)
            ))
        ]
    }


    public init(of property: KeyPath<Element, Int>, is maximum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: maximum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int8>, is maximum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: maximum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int16>, is maximum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: maximum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int32>, is maximum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: maximum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int64>, is maximum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: maximum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt8>, is maximum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: maximum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt16>, is maximum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: maximum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt32>, is maximum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: maximum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt64>, is maximum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: maximum, exclusive: exclusive, propertyName: propertyName)
    }


    public init(of property: KeyPath<Element, Float>, is maximum: Double, exclusive: Bool = false, propertyName: String) {
        self.init(value: maximum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Double>, is maximum: Double, exclusive: Bool = false, propertyName: String) {
        self.init(value: maximum, exclusive: exclusive, propertyName: propertyName)
    }
}
