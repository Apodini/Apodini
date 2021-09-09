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
    /// Type definition for the ``ExampleMetadata``.
    typealias Example = ExampleMetadata<Self>
}

public extension ContentMetadataNamespace {
    /// Type definition for the ``ExampleMetadata``.
    typealias Example<Element: Content> = ExampleMetadata<Element>
}

/// The ``ExampleMetadata`` can be used to add an example to a `Content` type or its properties.
///
/// The Metadata is available under the `ContentMetadataNamespace/Example` name and can be used like the following:
/// ```swift
/// struct ExampleContent: Content {
///     var someProperty: String
///     // ...
///     static var metadata: Metadata {
///         Example(ExampleContent(someProperty: "stringValue"))
///         Example(of: \.someProperty, "stringValue", propertyName: "someProperty")
///     }
/// }
/// ```
public struct ExampleMetadata<Element: Content>: ContentMetadataDefinition {
    public typealias Key = OpenAPIJSONSchemeModificationContextKey

    public let value: [JSONSchemeModificationType]

    public init(_ example: Element) {
        value = [
            .root(modification: PropertyModification(
                context: CoreContext.self,
                property: .example,
                value: AnyCodable.fromComplex(example)
            ))
        ]
    }

    public init<Value: Encodable>(for _: KeyPath<Element, Value>, _ example: Value, propertyName: String) {
        value = [
            .property(property: propertyName, modification: PropertyModification(
                context: CoreContext.self,
                property: .example,
                value: AnyCodable.fromComplex(example)
            ))
        ]
    }
}
