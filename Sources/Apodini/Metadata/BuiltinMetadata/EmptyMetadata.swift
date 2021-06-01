//
// Created by Andreas Bauer on 21.05.21.
//

extension HandlerMetadataNamespace {
    /// Name Definition for the `EmptyHandlerMetadata`
    public typealias Empty = EmptyHandlerMetadata
}

extension ComponentOnlyMetadataNamespace {
    /// Name Definition for the `EmptyComponentOnlyMetadata`
    public typealias Empty = EmptyComponentOnlyMetadata
}

extension WebServiceMetadataNamespace {
    /// Name Definition for the `EmptyWebServiceMetadata`
    public typealias Empty = EmptyWebServiceMetadata
}

extension ContentMetadataNamespace {
    /// Name Definition for the `EmptyContentMetadata`
    public typealias Empty = EmptyContentMetadata
}

extension ComponentMetadataBlockNamespace {
    /// Name Definition for the `EmptyComponentMetadata`
    public typealias Empty = EmptyComponentMetadata
}


/// `EmptyHandlerMetadata` is a `AnyHandlerMetadata` which in fact doesn't hold any Metadata.
/// The Metadata is available under the `Empty` name and can be used like the following:
/// ```swift
/// struct ExampleHandler: Handler {
///     // ...
///     var metadata: Metadata {
///         Empty()
///     }
/// }
/// ```
public struct EmptyHandlerMetadata: HandlerMetadataDefinition {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

/// `EmptyComponentOnlyMetadata` is a `ComponentOnlyMetadataDefinition` which in fact doesn't hold any Metadata.
/// The Metadata is available under the `Empty` name and can be used like the following:
/// ```swift
/// struct ExampleComponent: Component {
///     // ...
///     var metadata: Metadata {
///         Empty()
///     }
/// }
/// ```
public struct EmptyComponentOnlyMetadata: ComponentOnlyMetadataDefinition {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

/// `EmptyWebServiceMetadata` is a `AnyWebServiceMetadata` which in fact doesn't hold any Metadata.
/// The Metadata is available under the `Empty` name and can be used like the following:
/// ```swift
/// struct ExampleWebService: WebService {
///     // ...
///     var metadata: Metadata {
///         Empty()
///     }
/// }
/// ```
public struct EmptyWebServiceMetadata: WebServiceMetadataDefinition {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

/// `EmptyComponentMetadata` is a `AnyComponentMetadata` which in fact doesn't hold any Metadata.
/// The Metadata is available under the `Empty` name and can be used like the following:
/// ```swift
/// struct ExampleComponentMetadata: ComponentMetadataBlock {
///     var metadata: Metadata {
///         Empty()
///     }
/// }
/// ```
public struct EmptyComponentMetadata: ComponentMetadataDefinition {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

/// `EmptyContentMetadata` is a `AnyContentMetadata` which in fact doesn't hold any Metadata.
/// The Metadata is available under the `Empty` name and can be used like the following:
/// ```swift
/// struct ExampleContent: Content {
///     // ...
///     var metadata: Metadata {
///         Empty()
///     }
/// }
/// ```
public struct EmptyContentMetadata: ContentMetadataDefinition {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}
