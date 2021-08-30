//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import OpenAPIKit

public extension TypedContentMetadataNamespace {
    /// Name definition of the ``NumericMaximumMetadata``.
    typealias Maximum = NumericMaximumMetadata<Self>
}

public extension ContentMetadataNamespace {
    /// Name definition of the ``NumericMaximumMetadata``.
    typealias Maximum<Element: Content> = NumericMaximumMetadata<Element>
}


/// The ``NumericMaximumMetadata`` can be used to describe structural validations for numeric properties of a `Content` type.
///
/// The Metadata is available under the `ContentMetadataNamespace/Maximum` name and can be used like the following:
/// ```swift
/// struct ExampleContent: Content {
///     var number: Int
///     // ...
///     static var metadata: Metadata {
///         Maximum(of: \.number, is: 42, propertyName: "number")
///     }
/// }
/// ```
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
