//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public extension TypedContentMetadataNamespace {
    /// Name definition for the ``StringMinLengthMetadata``.
    typealias MinLength = StringMinLengthMetadata<Self>
}

public extension ContentMetadataNamespace {
    /// Name definition for the ``StringMinLengthMetadata``.
    typealias MinLength<Element: Content> = StringMinLengthMetadata<Element>
}

/// The ``StringMinLengthMetadata`` can be used to describe structural validations for string properties of a `Content` type.
///
/// The Metadata is available under the `ContentMetadataNamespace/MinLength` name and can be used like the following:
/// ```swift
/// struct ExampleContent: Content {
///     var text: String
///     // ...
///     static var metadata: Metadata {
///         MinLength(of: \.text, is: 2, propertyName: "text")
///     }
/// }
/// ```
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
