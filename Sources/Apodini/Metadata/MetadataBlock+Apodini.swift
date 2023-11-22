//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

public protocol AnyHandlerMetadataBlock: AnyMetadataBlock, AnyHandlerMetadata, HandlerMetadataNamespace, ComponentMetadataNamespace {}

public protocol AnyComponentOnlyMetadataBlock: AnyMetadataBlock, AnyComponentOnlyMetadata,
    ComponentOnlyMetadataNamespace, ComponentMetadataNamespace {}

public protocol AnyWebServiceMetadataBlock: AnyMetadataBlock, AnyWebServiceMetadata, WebServiceMetadataNamespace, ComponentMetadataNamespace {}

public protocol AnyComponentMetadataBlock: AnyMetadataBlock, AnyComponentMetadata, ComponentMetadataNamespace {}


/// The `HandlerMetadataBlock` protocol represents `AnyMetadataBlock`s which can only contain
/// `AnyHandlerMetadata` and itself can only be placed in `AnyHandlerMetadata` Declaration Blocks.
///
/// See `StandardHandlerMetadataBlock` for a general purpose `HandlerMetadataBlock` available by default.
///
/// By conforming to `HandlerMetadataBlock` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: HandlerMetadataBlock {
///     var metadata: Metadata {
///         Description("Example Description")
///         // ...
///     }
/// }
///
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         DefaultDescriptionMetadata()
///     }
/// }
/// ```
public protocol HandlerMetadataBlock: AnyHandlerMetadataBlock {
    associatedtype Metadata = AnyHandlerMetadata

    @MetadataBuilder<MetadataBuilderScope_Handler>
    var metadata: Metadata { get }
}

extension HandlerMetadataBlock {
    /// Returns the type erased metadata content of the `AnyMetadataBlock`.
    public var typeErasedContent: AnyMetadata {
        self.metadata as! AnyMetadata
    }
}

/// The `ComponentOnlyMetadataBlock` protocol represents `AnyMetadataBlock`s which can only contain
/// `AnyComponentOnlyMetadata` and itself can only be placed in `AnyComponentOnlyMetadata` Declaration Blocks.
///
/// By conforming to `ComponentOnlyMetadataBlock` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: ComponentOnlyMetadataBlock {
///     var metadata: Metadata {
///         Description("Example Description")
///         // ...
///     }
/// }
///
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         DefaultDescriptionMetadata()
///     }
/// }
/// ```
public protocol ComponentOnlyMetadataBlock: AnyComponentOnlyMetadataBlock {
    associatedtype Metadata = AnyComponentOnlyMetadata

    @MetadataBuilder<MetadataBuilderScope_ComponentOnly>
    var metadata: Metadata { get }
}

extension ComponentOnlyMetadataBlock {
    /// Returns the type erased metadata content of the `AnyMetadataBlock`.
    public var typeErasedContent: AnyMetadata {
        self.metadata as! AnyMetadata
    }
}

/// The `WebServiceMetadataBlock` protocol represents `AnyMetadataBlock`s which can only contain
/// `AnyWebServiceMetadata` and itself can only be placed in `AnyWebServiceMetadata` Declaration Blocks.
///
/// See `StandardWebServiceMetadataBlock` for a general purpose `WebServiceMetadataBlock` available by default.
///
/// By conforming to `WebServiceMetadataBlock` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: WebServiceMetadataBlock {
///     var metadata: Metadata {
///         Description("Example Description")
///         // ...
///     }
/// }
///
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         DefaultDescriptionMetadata()
///     }
/// }
/// ```
public protocol WebServiceMetadataBlock: AnyWebServiceMetadataBlock {
    associatedtype Metadata = AnyWebServiceMetadata

    @MetadataBuilder<MetadataBuilderScope_WebService>
    var metadata: Metadata { get }
}

extension WebServiceMetadataBlock {
    /// Returns the type erased metadata content of the `AnyMetadataBlock`.
    public var typeErasedContent: AnyMetadata {
        self.metadata as! AnyMetadata
    }
}

/// The `ComponentMetadataBlock` protocol represents `AnyMetadataBlock`s which can only contain
/// `AnyComponentMetadata` and itself can only be placed in `AnyComponentMetadata` Declaration Blocks.
///
/// See `StandardComponentMetadataBlock` for a general purpose `ComponentMetadataBlock` available by default.
///
/// By conforming to `ComponentMetadataBlock` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: ComponentMetadataBlock {
///     var metadata: Metadata {
///         Description("Example Description")
///         // ...
///     }
/// }
///
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         DefaultDescriptionMetadata()
///     }
/// }
/// ```
public protocol ComponentMetadataBlock: AnyComponentMetadataBlock {
    associatedtype Metadata = AnyComponentMetadata

    @ComponentMetadataBuilder
    var metadata: Metadata { get }
}

extension ComponentMetadataBlock {
    /// Returns the type erased metadata content of the `AnyMetadataBlock`.
    public var typeErasedContent: AnyMetadata {
        self.metadata as! AnyMetadata
    }
}

extension HandlerMetadataNamespace {
    /// Name definition for the `StandardHandlerMetadataBlock`
    public typealias Block = StandardHandlerMetadataBlock
}

extension ComponentOnlyMetadataNamespace {
    /// Name definition for the `StandardComponentOnlyMetadataBlock`
    public typealias Block = StandardComponentOnlyMetadataBlock
}

extension WebServiceMetadataNamespace {
    /// Name definition for the `StandardWebServiceMetadataBlock`
    public typealias Block = StandardWebServiceMetadataBlock
}

extension ComponentMetadataNamespace {
    /// Name definition for the `StandardComponentMetadataBlock`
    public typealias Block = StandardComponentMetadataBlock
}


/// `StandardHandlerMetadataBlock` is a `HandlerMetadataBlock` available by default.
/// It is available under the `Collect` name in `Handler` Metadata Declaration Blocks.
///
/// It may be used in `Handler` Metadata Declaration Blocks in the following way:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         // ...
///         Block {
///             // ...
///         }
///     }
/// }
/// ```
public struct StandardHandlerMetadataBlock: HandlerMetadataBlock {
    public var metadata: AnyHandlerMetadata

    public init(@MetadataBuilder<MetadataBuilderScope_Handler> metadata: () -> AnyHandlerMetadata) {
        self.metadata = metadata()
    }
}

/// `StandardComponentOnlyMetadataBlock` is a `ComponentOnlyMetadataBlock` available by default.
/// It is available under the `Collect` name in `Component` Metadata Declaration Blocks
/// (this includes `Handler`s and the `WebService`).
///
/// It may be used in `Component` Metadata Declaration Blocks in the following way:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         // ...
///         Block {
///             // ...
///         }
///     }
/// }
/// ```
public struct StandardComponentOnlyMetadataBlock: ComponentOnlyMetadataBlock {
    public var metadata: AnyComponentOnlyMetadata

    public init(@MetadataBuilder<MetadataBuilderScope_ComponentOnly> metadata: () -> AnyComponentOnlyMetadata) {
        self.metadata = metadata()
    }
}

/// `StandardWebServiceMetadataBlock` is a `WebServiceMetadataBlock` available by default.
/// It is available under the `Collect` name in `WebService` Metadata Declaration Blocks.
///
/// It may be used in `WebService` Metadata Declaration Blocks in the following way:
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         // ...
///         Block {
///             // ...
///         }
///     }
/// }
/// ```
public struct StandardWebServiceMetadataBlock: WebServiceMetadataBlock {
    public var metadata: AnyWebServiceMetadata

    public init(@MetadataBuilder<MetadataBuilderScope_WebService> metadata: () -> AnyWebServiceMetadata) {
        self.metadata = metadata()
    }
}

/// `StandardComponentMetadataBlock` is a `ComponentMetadataBlock` available by default.
/// It is available under the `Collect` name in `Component` Metadata Declaration Blocks
/// (this includes `Handler`s and the `WebService`).
///
/// It may be used in `Component` Metadata Declaration Blocks in the following way:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         // ...
///         Block {
///             // ...
///         }
///     }
/// }
/// ```
public struct StandardComponentMetadataBlock: ComponentMetadataBlock {
    public var metadata: AnyComponentMetadata

    public init(@ComponentMetadataBuilder metadata: () -> AnyComponentMetadata) {
        self.metadata = metadata()
    }
}
