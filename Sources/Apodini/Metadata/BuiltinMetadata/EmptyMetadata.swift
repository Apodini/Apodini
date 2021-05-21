//
// Created by Andreas Bauer on 21.05.21.
//

extension HandlerMetadataNamespace {
    public typealias Empty = EmptyHandlerMetadata
}

extension ComponentMetadataNamespace {
    public typealias Empty = EmptyComponentOnlyMetadata
}

extension WebServiceMetadataNamespace {
    public typealias Empty = EmptyWebServiceMetadata
}

extension ContentMetadataNamespace {
    public typealias Empty = EmptyContentMetadata
}


public struct EmptyHandlerMetadata: HandlerMetadataDefinition {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

public struct EmptyComponentOnlyMetadata: ComponentOnlyMetadataDefinition {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

public struct EmptyWebServiceMetadata: WebServiceMetadataDefinition {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

public struct EmptyComponentMetadata: ComponentMetadataDefinition {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

public struct EmptyContentMetadata: ContentMetadataDefinition {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}
