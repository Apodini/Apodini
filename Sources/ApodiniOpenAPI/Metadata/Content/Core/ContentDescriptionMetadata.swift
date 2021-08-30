//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public extension TypedContentMetadataNamespace {
    /// Name definition for the ``ContentDescriptionMetadata``
    typealias Description = ContentDescriptionMetadata<Self>
}

public extension ContentMetadataNamespace {
    /// Name definition for the ``ContentDescriptionMetadata``
    typealias Description<Element: Content> = ContentDescriptionMetadata<Element>
}

/// The ``ContentDescriptionMetadata`` can be used to add a Description to a ``Content``.
///
/// The Metadata is available under the `ContentMetadataNamespace/Description` name and can be used like the following:
/// ```swift
/// struct ExampleContent: Content {
///     // ...
///     var metadata: Metadata {
///         Description("Example Description")
///     }
/// }
/// ```
public struct ContentDescriptionMetadata<Element: Content>: ContentMetadataDefinition {
    public typealias Key = OpenAPIJSONSchemeModificationContextKey

    public let value: [JSONSchemeModificationType]

    /// Creates a new Description Metadata.
    /// - Parameter description: The description for the Content Type.
    public init(_ description: String) {
        self.value = [
            .root(modification: PropertyModification(context: CoreContext.self, property: .description, value: description))
        ]
    }

    /// Creates a new Description Metadata for a given property of a `Content` type.
    /// - Parameters:
    ///   - description: The description of the property.
    ///   - propertyName: The property name as a string.
    public init<Type>(of _: KeyPath<Element, Type>, _ description: String, propertyName: String) {
        self.value = [
            .property(property: propertyName, modification: PropertyModification(
                context: CoreContext.self,
                property: .description,
                value: description
            ))
        ]
    }
}
