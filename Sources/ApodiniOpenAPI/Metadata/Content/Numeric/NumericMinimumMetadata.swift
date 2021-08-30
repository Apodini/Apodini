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
    typealias Minimum = NumericMinimumMetadata<Self>
}

public extension ContentMetadataNamespace {
    typealias Minimum<Element: Content> = NumericMinimumMetadata<Element>
}

public struct NumericMinimumMetadata<Element: Content>: ContentMetadataDefinition {
    public typealias Key = OpenAPIJSONSchemeModificationContextKey

    public let value: [JSONSchemeModificationType]

    /// Initializer for Integer MultipleOf
    private init(value: Int, exclusive: Bool, propertyName: String) {
        self.value = [
            .property(property: propertyName, modification: PropertyModification(
                context: IntegerContext.self,
                property: .minimum,
                value: (value, exclusive: exclusive)
            ))
        ]
    }

    /// Initializer for Integer MultipleOf
    private init(value: Double, exclusive: Bool, propertyName: String) {
        self.value = [
            .property(property: propertyName, modification: PropertyModification(
                context: NumericContext.self,
                property: .minimum,
                value: (value, exclusive: exclusive)
            ))
        ]
    }


    public init(of property: KeyPath<Element, Int>, is minimum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: minimum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int8>, is minimum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: minimum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int16>, is minimum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: minimum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int32>, is minimum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: minimum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Int64>, is minimum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: minimum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt8>, is minimum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: minimum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt16>, is minimum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: minimum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt32>, is minimum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: minimum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, UInt64>, is minimum: Int, exclusive: Bool = false, propertyName: String) {
        self.init(value: minimum, exclusive: exclusive, propertyName: propertyName)
    }


    public init(of property: KeyPath<Element, Float>, is minimum: Double, exclusive: Bool = false, propertyName: String) {
        self.init(value: minimum, exclusive: exclusive, propertyName: propertyName)
    }

    public init(of property: KeyPath<Element, Double>, is minimum: Double, exclusive: Bool = false, propertyName: String) {
        self.init(value: minimum, exclusive: exclusive, propertyName: propertyName)
    }
}
