//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

public struct WebServiceDescriptionContextKey: OptionalContextKey {
    public typealias Value = String
}

public struct DescriptionContextKey: OptionalContextKey {
    public typealias Value = String
}


extension WebServiceMetadataNamespace {
    /// Name definition for the ``WebServiceDescriptionMetadata``
    public typealias Description = WebServiceDescriptionMetadata
}

extension HandlerMetadataNamespace {
    /// Name definition for the ``HandlerDescriptionMetadata``
    public typealias Description = HandlerDescriptionMetadata
}

extension ContentMetadataNamespace {
    /// Name definition for the ``ContentDescriptionMetadata``
    public typealias Description = ContentDescriptionMetadata
}


/// The ``WebServiceDescriptionMetadata`` can be used to add a Description to a ``WebService``.
///
/// The Metadata is available under the ``WebServiceMetadataNamespace/Description`` name and can be used like the following:
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         Description("Example Description")
///     }
/// }
/// ```
public struct WebServiceDescriptionMetadata: WebServiceMetadataDefinition {
    public typealias Key = WebServiceDescriptionContextKey
    public let value: String

    public init(_ description: String) {
        self.value = description
    }
}

/// The ``HandlerDescriptionMetadata`` can be used to add a Description to a ``Handler``.
///
/// The Metadata is available under the ``HandlerMetadataNamespace/Description`` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         Description("Example Description")
///     }
/// }
/// ```
public struct HandlerDescriptionMetadata: HandlerMetadataDefinition {
    public typealias Key = DescriptionContextKey
    public let value: String

    /// Creates a new Description Metadata
    /// - Parameter description: The description for the Component.
    public init(_ description: String) {
        self.value = description
    }
}

/// The ``ContentDescriptionMetadata`` can be used to add a Description to a ``Content``.
///
/// The Metadata is available under the ``ContentMetadataNamespace/Description`` name and can be used like the following:
/// ```swift
/// struct ExampleContent: Content {
///     // ...
///     var metadata: Metadata {
///         Description("Example Description")
///     }
/// }
/// ```
public struct ContentDescriptionMetadata: ContentMetadataDefinition {
    public typealias Key = DescriptionContextKey
    public let value: String

    /// Creates a new Description Metadata.
    /// - Parameter description: The description for the Content Type.
    public init(_ description: String) {
        self.value = description
    }
}


extension Handler {
    /// A `description` Modifier can be used to specify the `DescriptionMetadata` via a `HandlerModifier`.
    /// - Parameter description: The `description` that is used to for the `Handler`.
    /// - Returns: The modified `Handler` with the `DescriptionMetadata` added.
    public func description(_ value: String) -> HandlerMetadataModifier<Self> {
        HandlerMetadataModifier(modifies: self, with: HandlerDescriptionMetadata(value))
    }
}
