//
// Created by Andreas Bauer on 21.05.21.
//

extension HandlerMetadataScope {
    public typealias Empty = EmptyHandlerMetadata
}

extension ComponentMetadataScope {
    public typealias Empty = EmptyComponentOnlyMetadata
}

extension WebServiceMetadataScope {
    public typealias Empty = EmptyWebServiceMetadata
}

extension ContentMetadataScope {
    public typealias Empty = EmptyContentMetadata
}


public struct EmptyHandlerMetadata: HandlerMetadataDeclaration {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

public struct EmptyComponentOnlyMetadata: ComponentOnlyMetadataDeclaration {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

public struct EmptyWebServiceMetadata: WebServiceMetadataDeclaration {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

public struct EmptyComponentMetadata: ComponentMetadataDeclaration {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}

public struct EmptyContentMetadata: ContentMetadataDeclaration {
    public typealias Key = Never

    public var value: Key.Value {
        fatalError("Cannot access the value of an empty metadata!")
    }

    public func accept(_ visitor: SyntaxTreeVisitor) {}
}
