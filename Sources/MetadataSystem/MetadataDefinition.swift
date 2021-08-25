//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import ApodiniContext

/// A `MetadataDefinition` represents a specific type of Metadata which can be declared
/// on appropriate locations, like in the Metadata Declaration blocks of a `Component`.
///
/// - Note: When creating ``MetadataDefinition``s it is advised to give them unique and precise names.
///     The Metadata DSL subsystem is designed in such a way, that the Type name itself will and should
///     not be the name used by the user in the Metadata DSL. Therefore there is no reason to keep the names short
///     or name them according to some "natural language flow". Ideally all such definitions should
///     have the "Metadata" suffix (maybe adding even the scope e.g. "XXXXHandlerMetadata").
///     The name used in the Metadata DSL (the one which should ideally reflect the "natural language flow")
///     can be defined by extending the appropriate Metadata Namespace: `ComponentMetadataNamespace`,
///     `HandlerMetadataNamespace`, `WebServiceMetadataNamespace` or `ContentMetadataNamespace`.
public protocol MetadataDefinition: AnyMetadata {
    /// Either a `OptionalContextKey` or `ContextKey` used to store and identify the Metadata value.
    associatedtype Key: OptionalContextKey

    /// The value which is to be stored.
    var value: Key.Value { get }
    /// The `Scope` in which the value is stored.
    /// In most cases you should not need to provide a custom value for this property.
    /// Apodini provides strong defaults, `Scope.current` for most Metadata and
    /// `Scope.environment` for Component Metadata.
    static var scope: Scope { get }
}

public extension MetadataDefinition {
    /// The default `Scope` for all ``MetadataDefinition``s is `Scope/current`.
    static var scope: Scope {
        .current
    }
}

// MARK: MetadataParser
public extension MetadataDefinition {
    /// Default implementation to visit this metadata.
    func collectMetadata(_ visitor: MetadataParser) {
        visitor._visit(definition: self)
    }
}
