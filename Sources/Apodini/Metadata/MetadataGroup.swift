//
// Created by Andreas Bauer on 16.05.21.
//

/// The `AnyMetadataGroup` protocol represents Metadata that is _somehow_ grouped together.
/// How the Metadata is grouped and how it is made accessible is the responsibility
/// of the one conforming to this protocol or of the protocol inheriting from this one.
///
/// The following Metadata Groups are available:
/// - `HandlerMetadataGroup`
/// - `ComponentOnlyMetadataGroup`
/// - `WebServiceMetadataGroup`
/// - `ComponentMetadataGroup`
/// - `ContentMetadataGroup`
///
/// See those docs for examples on how to use them in their respective scope
/// or on how to create **independent** and thus **reusable** Metadata.
///
/// See `RestrictedMetadataGroup` for a way to create custom Metadata Groups where
/// the content is restricted to a specific `MetadataDefinition`.
public protocol AnyMetadataGroup: AnyMetadata {}

/// The `HandlerMetadataGroup` protocol represents `AnyMetadataGroup`s which can only contain
/// `AnyHandlerMetadata` and itself can only be placed in `AnyHandlerMetadata` Declaration Blocks.
///
/// See `StandardHandlerMetadataGroup` for a general purpose `HandlerMetadataGroup` available by default.
///
/// By conforming to `HandlerMetadataGroup` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: HandlerMetadataGroup {
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
public protocol HandlerMetadataGroup: AnyMetadataGroup, AnyHandlerMetadata, HandlerMetadataNamespace, ComponentMetadataNamespace {
    associatedtype Metadata = AnyHandlerMetadata

    @MetadataBuilder
    var content: AnyHandlerMetadata { get }
}

extension HandlerMetadataGroup {
    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataGroup`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}

/// The `ComponentOnlyMetadataGroup` protocol represents `AnyMetadataGroup`s which can only contain
/// `AnyComponentOnlyMetadata` and itself can only be placed in `AnyComponentOnlyMetadata` Declaration Blocks.
///
/// By conforming to `ComponentOnlyMetadataGroup` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: ComponentOnlyMetadataGroup {
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
public protocol ComponentOnlyMetadataGroup: AnyMetadataGroup, AnyComponentOnlyMetadata, ComponentMetadataNamespace {
    associatedtype Metadata = AnyComponentOnlyMetadata

    @MetadataBuilder
    var content: AnyComponentOnlyMetadata { get }
}

extension ComponentOnlyMetadataGroup {
    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataGroup`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}

/// The `WebServiceMetadataGroup` protocol represents `AnyMetadataGroup`s which can only contain
/// `AnyWebServiceMetadata` and itself can only be placed in `AnyWebServiceMetadata` Declaration Blocks.
///
/// See `StandardWebServiceMetadataGroup` for a general purpose `WebServiceMetadataGroup` available by default.
///
/// By conforming to `WebServiceMetadataGroup` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: WebServiceMetadataGroup {
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
public protocol WebServiceMetadataGroup: AnyMetadataGroup, AnyWebServiceMetadata, WebServiceMetadataNamespace, ComponentMetadataNamespace {
    associatedtype Metadata = AnyWebServiceMetadata

    @MetadataBuilder
    var content: AnyWebServiceMetadata { get }
}

extension WebServiceMetadataGroup {
    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataGroup`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}

/// The `ComponentMetadataGroup` protocol represents `AnyMetadataGroup`s which can only contain
/// `AnyComponentMetadata` and itself can only be placed in `AnyComponentMetadata` Declaration Blocks.
///
/// See `StandardComponentMetadataGroup` for a general purpose `ComponentMetadataGroup` available by default.
///
/// By conforming to `ComponentMetadataGroup` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: ComponentMetadataGroup {
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
public protocol ComponentMetadataGroup: AnyMetadataGroup, AnyComponentMetadata, ComponentMetadataNamespace {
    associatedtype Metadata = AnyComponentMetadata

    @ComponentMetadataBuilder
    var content: AnyComponentMetadata { get }
}

extension ComponentMetadataGroup {
    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataGroup`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}

/// The `ContentMetadataGroup` protocol represents `AnyMetadataGroup`s which can only contain
/// `AnyContentMetadata` and itself can only be placed in `AnyContentMetadata` Declaration Blocks.
///
/// See `StandardContentMetadataGroup` for a general purpose `ContentMetadataGroup` available by default.
///
/// By conforming to `ContentMetadataGroup` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: ContentMetadataGroup {
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
public protocol ContentMetadataGroup: AnyMetadataGroup, AnyContentMetadata, ContentMetadataNamespace {
    associatedtype Metadata = AnyContentMetadata

    @MetadataBuilder
    var content: AnyContentMetadata { get }
}

extension ContentMetadataGroup {
    /// Forwards the `SyntaxTreeVisitor` to the content of the `AnyMetadataGroup`
    /// - Parameter visitor: `SyntaxTreeVisitor` responsible for parsing the Metadata Tree
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}


extension ComponentMetadataNamespace {
    /// Name Definition for the `StandardComponentMetadataGroup`
    public typealias Collect = StandardComponentMetadataGroup
}

extension HandlerMetadataNamespace {
    /// Name Definition for the `StandardHandlerMetadataGroup`
    public typealias Collect = StandardHandlerMetadataGroup
}

extension WebServiceMetadataNamespace {
    /// Name Definition for the `StandardWebServiceMetadataGroup`
    public typealias Collect = StandardWebServiceMetadataGroup
}

extension ContentMetadataNamespace {
    /// Name Definition for the `StandardContentMetadataGroup`
    public typealias Collect = StandardContentMetadataGroup
}


/// `StandardHandlerMetadataGroup` is a `HandlerMetadataGroup` available by default.
/// It is available under the `Collect` name in `Handler` Metadata Declaration Blocks.
///
/// It may be used in `Handler` Metadata Declaration Blocks in the following way:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         // ...
///         Collect {
///             // ...
///         }
///     }
/// }
/// ```
public struct StandardHandlerMetadataGroup: HandlerMetadataGroup {
    public var content: AnyHandlerMetadata

    public init(@MetadataBuilder content: () -> AnyHandlerMetadata) {
        self.content = content()
    }
}

/// `StandardComponentMetadataGroup` is a `ComponentMetadataGroup` available by default.
/// It is available under the `Collect` name in `Component` Metadata Declaration Blocks
/// (this includes `Handler`s and the `WebService`).
///
/// It may be used in `Component` Metadata Declaration Blocks in the following way:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         // ...
///         Collect {
///             // ...
///         }
///     }
/// }
/// ```
public struct StandardComponentMetadataGroup: ComponentMetadataGroup {
    public var content: AnyComponentMetadata
    
    public init(@MetadataBuilder content: () -> AnyComponentMetadata) {
        self.content = content()
    }
}

/// `StandardWebServiceMetadataGroup` is a `WebServiceMetadataGroup` available by default.
/// It is available under the `Collect` name in `WebService` Metadata Declaration Blocks.
///
/// It may be used in `WebService` Metadata Declaration Blocks in the following way:
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         // ...
///         Collect {
///             // ...
///         }
///     }
/// }
/// ```
public struct StandardWebServiceMetadataGroup: WebServiceMetadataGroup {
    public var content: AnyWebServiceMetadata
    
    public init(@MetadataBuilder content: () -> AnyWebServiceMetadata) {
        self.content = content()
    }
}

/// `StandardContentMetadataGroup` is a `ContentMetadataGroup` available by default.
/// It is available under the `Collect` name in `Content` Metadata Declaration Blocks.
///
/// It may be used in `Content` Metadata Declaration Blocks in the following way:
/// ```swift
/// struct ExampleContent: Content {
///     // ...
///     static var metadata: Metadata {
///         // ...
///         Collect {
///             // ...
///         }
///     }
/// }
/// ```
public struct StandardContentMetadataGroup: ContentMetadataGroup {
    public var content: AnyContentMetadata
    
    public init(@MetadataBuilder content: () -> AnyContentMetadata) {
        self.content = content()
    }
}
