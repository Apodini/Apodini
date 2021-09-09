//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public extension TypedContentMetadataNamespace {
    /// Name definition for the ``StringMaxLengthMetadata``.
    typealias MaxLength = StringMaxLengthMetadata<Self>
}

public extension ContentMetadataNamespace {
    /// Name definition for the ``StringMaxLengthMetadata``.
    typealias MaxLength<Element: Content> = StringMaxLengthMetadata<Element>
}

/// The ``StringMaxLengthMetadata`` can be used to describe structural validations for string properties of a `Content` type.
///
/// The Metadata is available under the `ContentMetadataNamespace/MaxLength` name and can be used like the following:
/// ```swift
/// struct ExampleContent: Content {
///     var text: String
///     // ...
///     static var metadata: Metadata {
///         MaxLength(of: \.text, is: 255, propertyName: "text")
///     }
/// }
/// ```
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
