//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

extension HandlerMetadataNamespace {
    /// Name definition for the `EmptyHandlerMetadata`
    public typealias Empty = EmptyHandlerMetadata
}

extension ComponentOnlyMetadataNamespace {
    /// Name definition for the `EmptyComponentOnlyMetadata`
    public typealias Empty = EmptyComponentOnlyMetadata
}

extension WebServiceMetadataNamespace {
    /// Name definition for the `EmptyWebServiceMetadata`
    public typealias Empty = EmptyWebServiceMetadata
}

extension ComponentMetadataBlockNamespace {
    /// Name definition for the `EmptyComponentMetadata`
    public typealias Empty = EmptyComponentMetadata
}


/// `EmptyHandlerMetadata` is a `AnyHandlerMetadata` which in fact doesn't hold any Metadata.
/// The Metadata is available under the `HandlerMetadataNamespace.Empty` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         Empty()
///     }
/// }
/// ```
public struct EmptyHandlerMetadata: EmptyMetadata, HandlerMetadataDefinition {
    public init() {}
}

/// `EmptyComponentOnlyMetadata` is a `ComponentOnlyMetadataDefinition` which in fact doesn't hold any Metadata.
/// The Metadata is available under the `ComponentOnlyMetadataNamespace.Empty` name and can be used like the following:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         Empty()
///     }
/// }
/// ```
public struct EmptyComponentOnlyMetadata: EmptyMetadata, ComponentOnlyMetadataDefinition {
    public init() {}
}

/// `EmptyWebServiceMetadata` is a `AnyWebServiceMetadata` which in fact doesn't hold any Metadata.
/// The Metadata is available under the `WebServiceMetadataNamespace.Empty` name and can be used like the following:
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         Empty()
///     }
/// }
/// ```
public struct EmptyWebServiceMetadata: EmptyMetadata, WebServiceMetadataDefinition {
    public init() {}
}

/// `EmptyComponentMetadata` is a `AnyComponentMetadata` which in fact doesn't hold any Metadata.
/// The Metadata is available under the `ComponentMetadataBlockNamespace.Empty` name and can be used like the following:
/// ```swift
/// struct ExampleComponentMetadata: ComponentMetadataBlock {
///     var metadata: Metadata {
///         Empty()
///     }
/// }
/// ```
public struct EmptyComponentMetadata: EmptyMetadata, ComponentMetadataDefinition {
    public init() {}
}
