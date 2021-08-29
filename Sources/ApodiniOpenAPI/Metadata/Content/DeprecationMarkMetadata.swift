//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public extension TypedContentMetadataNamespace {
    /// Name definition for the ``DeprecationMarkMetadata``
    typealias MarkDeprecated = DeprecationMarkMetadata<Self>
}

public extension ContentMetadataNamespace {
    /// Name definition for the ``DeprecationMarkMetadata``
    typealias MarkDeprecated<Element: Content> = DeprecationMarkMetadata<Element>
}

public struct DeprecationMarkMetadata<Element: Content>: ContentMetadataDefinition {
    public typealias Key = OpenAPIJSONSchemeModificationContextKey

    public let value: [JSONSchemeModificationType]

    public init (_ deprecation: Bool = true) {
        value = [
            .root(modification: PropertyModification(
                context: CoreContext.self,
                property: .deprecated,
                value: deprecation
            ))
        ]
    }

    public init<Value>(property _: KeyPath<Element, Value>, _ deprecation: Bool = true, propertyName: String) {
        value = [
            .property(property: propertyName, modification: PropertyModification(
                context: CoreContext.self,
                property: .deprecated,
                value: deprecation
            ))
        ]
    }
}
