//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// The `AnyMetadataBlock` protocol represents Metadata that is _somehow_ grouped together.
/// How the Metadata is grouped and how it is made accessible is the responsibility
/// of the one conforming to this protocol or of the protocol inheriting from this one.
///
/// The following Metadata Blocks are available:
/// - `HandlerMetadataBlock`
/// - `ComponentOnlyMetadataBlock`
/// - `WebServiceMetadataBlock`
/// - `ComponentMetadataBlock`
/// - `ContentMetadataBlock`
///
/// See those docs for examples on how to use them in their respective scope
/// or on how to create **independent** and thus **reusable** Metadata.
///
/// See `RestrictedMetadataBlock` for a way to create custom Metadata Blocks where
/// the content is restricted to a specific `MetadataDefinition`.
public protocol AnyMetadataBlock: AnyMetadata {
    var blockContent: AnyMetadata { get }
}

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
public protocol HandlerMetadataBlock: AnyMetadataBlock, AnyHandlerMetadata, HandlerMetadataNamespace, ComponentMetadataNamespace {
    associatedtype Metadata = AnyHandlerMetadata

    @MetadataBuilder
    var metadata: AnyHandlerMetadata { get }
}

extension HandlerMetadataBlock {
    /// Returns the type erased metadata content of the ``AnyMetadataBlock``.
    public var blockContent: AnyMetadata {
        self.metadata
    }

    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataBlock`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func collectMetadata(_ visitor: SyntaxTreeVisitor) {
        metadata.collectMetadata(visitor)
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
public protocol ComponentOnlyMetadataBlock: AnyMetadataBlock, AnyComponentOnlyMetadata, ComponentOnlyMetadataNamespace, ComponentMetadataNamespace {
    associatedtype Metadata = AnyComponentOnlyMetadata

    @MetadataBuilder
    var metadata: AnyComponentOnlyMetadata { get }
}

extension ComponentOnlyMetadataBlock {
    /// Returns the type erased metadata content of the ``AnyMetadataBlock``.
    public var blockContent: AnyMetadata {
        self.metadata
    }

    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataBlock`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func collectMetadata(_ visitor: SyntaxTreeVisitor) {
        metadata.collectMetadata(visitor)
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
public protocol WebServiceMetadataBlock: AnyMetadataBlock, AnyWebServiceMetadata, WebServiceMetadataNamespace, ComponentMetadataNamespace {
    associatedtype Metadata = AnyWebServiceMetadata

    @MetadataBuilder
    var metadata: AnyWebServiceMetadata { get }
}

extension WebServiceMetadataBlock {
    /// Returns the type erased metadata content of the ``AnyMetadataBlock``.
    public var blockContent: AnyMetadata {
        self.metadata
    }

    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataBlock`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func collectMetadata(_ visitor: SyntaxTreeVisitor) {
        metadata.collectMetadata(visitor)
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
public protocol ComponentMetadataBlock: AnyMetadataBlock, AnyComponentMetadata, ComponentMetadataNamespace {
    associatedtype Metadata = AnyComponentMetadata

    @ComponentMetadataBuilder
    var metadata: AnyComponentMetadata { get }
}

extension ComponentMetadataBlock {
    /// Returns the type erased metadata content of the ``AnyMetadataBlock``.
    public var blockContent: AnyMetadata {
        self.metadata
    }

    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataBlock`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func collectMetadata(_ visitor: SyntaxTreeVisitor) {
        metadata.collectMetadata(visitor)
    }
}

/// The `ContentMetadataBlock` protocol represents `AnyMetadataBlock`s which can only contain
/// `AnyContentMetadata` and itself can only be placed in `AnyContentMetadata` Declaration Blocks.
///
/// See `StandardContentMetadataBlock` for a general purpose `ContentMetadataBlock` available by default.
///
/// By conforming to `ContentMetadataBlock` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: ContentMetadataBlock {
///     var metadata: Metadata {
///         Description("Example Description")
///         // ...
///     }
/// }
///
/// struct ExampleContent: Content {
///     // ...
///     static var metadata: Metadata {
///         DefaultDescriptionMetadata()
///     }
/// }
/// ```
public protocol ContentMetadataBlock: AnyMetadataBlock, AnyContentMetadata, ContentMetadataNamespace {
    associatedtype Metadata = AnyContentMetadata

    @ContentMetadataBuilder
    var metadata: AnyContentMetadata { get }
}

extension ContentMetadataBlock {
    /// Returns the type erased metadata content of the ``AnyMetadataBlock``.
    public var blockContent: AnyMetadata {
        self.metadata
    }

    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataBlock`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func collectMetadata(_ visitor: SyntaxTreeVisitor) {
        metadata.collectMetadata(visitor)
    }
}

extension HandlerMetadataNamespace {
    /// Name Definition for the `StandardHandlerMetadataBlock`
    public typealias Block = StandardHandlerMetadataBlock
}

extension ComponentOnlyMetadataNamespace {
    /// Name Definition for the `StandardComponentOnlyMetadataBlock`
    public typealias Block = StandardComponentOnlyMetadataBlock
}

extension WebServiceMetadataNamespace {
    /// Name Definition for the `StandardWebServiceMetadataBlock`
    public typealias Block = StandardWebServiceMetadataBlock
}

extension ComponentMetadataNamespace {
    /// Name Definition for the `StandardComponentMetadataBlock`
    public typealias Block = StandardComponentMetadataBlock
}

extension ContentMetadataNamespace {
    /// Name Definition for the `StandardContentMetadataBlock`
    public typealias Block = StandardContentMetadataBlock
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

    public init(@MetadataBuilder metadata: () -> AnyHandlerMetadata) {
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

    public init(@MetadataBuilder metadata: () -> AnyComponentOnlyMetadata) {
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
    
    public init(@MetadataBuilder metadata: () -> AnyWebServiceMetadata) {
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

/// `StandardContentMetadataBlock` is a `ContentMetadataBlock` available by default.
/// It is available under the `Collect` name in `Content` Metadata Declaration Blocks.
///
/// It may be used in `Content` Metadata Declaration Blocks in the following way:
/// ```swift
/// struct ExampleContent: Content {
///     // ...
///     static var metadata: Metadata {
///         // ...
///         Block {
///             // ...
///         }
///     }
/// }
/// ```
public struct StandardContentMetadataBlock: ContentMetadataBlock {
    public var metadata: AnyContentMetadata
    
    public init(@ContentMetadataBuilder metadata: () -> AnyContentMetadata) {
        self.metadata = metadata()
    }
}
