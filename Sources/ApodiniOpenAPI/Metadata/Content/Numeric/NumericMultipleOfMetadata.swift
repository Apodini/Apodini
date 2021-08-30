//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public extension TypedContentMetadataNamespace {
    /// Name definition for the ``NumericMultipleOfMetadata``.
    typealias MultipleOf = NumericMultipleOfMetadata<Self>
}

public extension ContentMetadataNamespace {
    /// Name definition for the ``NumericMultipleOfMetadata``.
    typealias MultipleOf<Element: Content> = NumericMultipleOfMetadata<Element>
}

/// The ``NumericMultipleOfMetadata`` can be used to describe structural validations for numeric properties of a `Content` type.
///
/// The Metadata is available under the `ContentMetadataNamespace/MultipleOf` name and can be used like the following:
/// ```swift
/// struct ExampleContent: Content {
///     var number: Int
///     // ...
///     static var metadata: Metadata {
///         MultipleOf(of: \.number, is: 2, propertyName: "number")
///     }
/// }
/// ```
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
