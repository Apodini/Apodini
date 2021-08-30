//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public extension TypedContentMetadataNamespace {
    typealias MultipleOf = NumericMultipleOfMetadata<Self>
}

public extension ContentMetadataNamespace {
    typealias MultipleOf<Element: Content> = NumericMultipleOfMetadata<Element>
}

public struct NumericMultipleOfMetadata<Element: Content>: ContentMetadataDefinition {
    public typealias Key = OpenAPIJSONSchemeModificationContextKey

    public let value: [JSONSchemeModificationType]

    /// Initializer for Integer MultipleOf
    private init(multipleOf: Int, propertyName: String) {
        self.value = [
            .property(property: propertyName, modification: PropertyModification(
                context: IntegerContext.self,
                property: .multipleOf,
                value: multipleOf
            ))
        ]
    }

    /// Initializer for Integer MultipleOf
    private init(multipleOf: Double, propertyName: String) {
        self.value = [
            .property(property: propertyName, modification: PropertyModification(
                context: NumericContext.self,
                property: .multipleOf,
                value: multipleOf
            ))
        ]
    }


    public init(of property: KeyPath<Element, Int>, is multipleOf: Int, propertyName: String) {
        self.init(multipleOf: multipleOf, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int8>, is multipleOf: Int, propertyName: String) {
        self.init(multipleOf: multipleOf, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int16>, is multipleOf: Int, propertyName: String) {
        self.init(multipleOf: multipleOf, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int32>, is multipleOf: Int, propertyName: String) {
        self.init(multipleOf: multipleOf, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int64>, is multipleOf: Int, propertyName: String) {
        self.init(multipleOf: multipleOf, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt8>, is multipleOf: Int, propertyName: String) {
        self.init(multipleOf: multipleOf, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt16>, is multipleOf: Int, propertyName: String) {
        self.init(multipleOf: multipleOf, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt32>, is multipleOf: Int, propertyName: String) {
        self.init(multipleOf: multipleOf, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt64>, is multipleOf: Int, propertyName: String) {
        self.init(multipleOf: multipleOf, propertyName: propertyName)
    }


    public init(of property: KeyPath<Element, Float>, is multipleOf: Double, propertyName: String) {
        self.init(multipleOf: multipleOf, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Double>, is multipleOf: Double, propertyName: String) {
        self.init(multipleOf: multipleOf, propertyName: propertyName)
    }
}
