//
// Created by Andreas Bauer on 16.05.21.
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
public protocol AnyMetadataBlock: AnyMetadata {}

/// The `HandlerMetadataBlock` protocol represents `AnyMetadataBlock`s which can only contain
/// `AnyHandlerMetadata` and itself can only be placed in `AnyHandlerMetadata` Declaration Blocks.
///
/// See `StandardHandlerMetadataBlock` for a general purpose `HandlerMetadataBlock` available by default.
///
/// By conforming to `HandlerMetadataBlock` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: HandlerMetadataBlock {
///     var content: Metadata {
///         Description("Example Description")
///         // ...
///     }
/// }
///
/// struct ExampleHandler: Handler {
///     // ...
///     var content: Metadata {
///         DefaultDescriptionMetadata()
///     }
/// }
/// ```
public protocol HandlerMetadataBlock: AnyMetadataBlock, AnyHandlerMetadata, HandlerMetadataNamespace, ComponentMetadataNamespace {
    associatedtype Metadata = AnyHandlerMetadata

    @MetadataBuilder
    var content: AnyHandlerMetadata { get }
}

extension HandlerMetadataBlock {
    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataBlock`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}

/// The `ComponentOnlyMetadataBlock` protocol represents `AnyMetadataBlock`s which can only contain
/// `AnyComponentOnlyMetadata` and itself can only be placed in `AnyComponentOnlyMetadata` Declaration Blocks.
///
/// By conforming to `ComponentOnlyMetadataBlock` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: ComponentOnlyMetadataBlock {
///     var content: Metadata {
///         Description("Example Description")
///         // ...
///     }
/// }
///
/// struct ExampleComponent: Component {
///     // ...
///     var content: Metadata {
///         DefaultDescriptionMetadata()
///     }
/// }
/// ```
public protocol ComponentOnlyMetadataBlock: AnyMetadataBlock, AnyComponentOnlyMetadata, ComponentOnlyMetadataNamespace, ComponentMetadataNamespace {
    associatedtype Metadata = AnyComponentOnlyMetadata

    @MetadataBuilder
    var content: AnyComponentOnlyMetadata { get }
}

extension ComponentOnlyMetadataBlock {
    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataBlock`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
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
///     var content: Metadata {
///         Description("Example Description")
///         // ...
///     }
/// }
///
/// struct ExampleWebService: WebService {
///     // ...
///     var content: Metadata {
///         DefaultDescriptionMetadata()
///     }
/// }
/// ```
public protocol WebServiceMetadataBlock: AnyMetadataBlock, AnyWebServiceMetadata, WebServiceMetadataNamespace, ComponentMetadataNamespace {
    associatedtype Metadata = AnyWebServiceMetadata

    @MetadataBuilder
    var content: AnyWebServiceMetadata { get }
}

extension WebServiceMetadataBlock {
    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataBlock`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
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
///     var content: Metadata {
///         Description("Example Description")
///         // ...
///     }
/// }
///
/// struct ExampleComponent: Component {
///     // ...
///     var content: Metadata {
///         DefaultDescriptionMetadata()
///     }
/// }
/// ```
public protocol ComponentMetadataBlock: AnyMetadataBlock, AnyComponentMetadata, ComponentMetadataNamespace {
    associatedtype Metadata = AnyComponentMetadata

    @ComponentMetadataBuilder
    var content: AnyComponentMetadata { get }
}

extension ComponentMetadataBlock {
    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataBlock`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
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
///     var content: Metadata {
///         Description("Example Description")
///         // ...
///     }
/// }
///
/// struct ExampleContent: Content {
///     // ...
///     static var content: Metadata {
///         DefaultDescriptionMetadata()
///     }
/// }
/// ```
public protocol ContentMetadataBlock: AnyMetadataBlock, AnyContentMetadata, ContentMetadataNamespace {
    associatedtype Metadata = AnyContentMetadata

    @ContentMetadataBuilder
    var content: AnyContentMetadata { get }
}

extension ContentMetadataBlock {
    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataBlock`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
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
    public var content: AnyHandlerMetadata

    public init(@MetadataBuilder content: () -> AnyHandlerMetadata) {
        self.content = content()
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
    public var content: AnyComponentOnlyMetadata

    public init(@MetadataBuilder content: () -> AnyComponentOnlyMetadata) {
        self.content = content()
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
    public var content: AnyWebServiceMetadata
    
    public init(@MetadataBuilder content: () -> AnyWebServiceMetadata) {
        self.content = content()
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
    public var content: AnyComponentMetadata

    public init(@ComponentMetadataBuilder content: () -> AnyComponentMetadata) {
        self.content = content()
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
    public var content: AnyContentMetadata
    
    public init(@ContentMetadataBuilder content: () -> AnyContentMetadata) {
        self.content = content()
    }
}
