//
// Created by Andreas Bauer on 16.05.21.
//

public protocol MetadataContainer: SyntaxTreeVisitable {
    var content: AnyMetadata { get }
}

public extension MetadataContainer {
    func accept(_ visitor: SyntaxTreeVisitor) {
        print("ACCEPING \(content)")
        content.accept(visitor)
    }
}


public struct WebServiceMetadataContainer: MetadataContainer {
    public var content: AnyMetadata

    init() {
        self.init(EmptyWebServiceMetadata())
    }
    
    init(_ content: AnyMetadata) {
        self.content = content
    }
}

public struct HandlerMetadataContainer: MetadataContainer {
    public var content: AnyMetadata

    init() {
        self.init(EmptyHandlerMetadata())
    }
    
    init(_ content: AnyMetadata) {
        self.content = content
    }
}

public struct ComponentMetadataContainer: MetadataContainer {
    public var content: AnyMetadata

    init() {
        self.init(EmptyComponentMetadata())
    }
    
    init(_ content: AnyMetadata) {
        self.content = content
    }
}

public struct ContentMetadataContainer: MetadataContainer {
    public var content: AnyMetadata

    init() {
        self.init(EmptyContentMetadata())
    }
    
    init(_ content: AnyMetadata) {
        self.content = content
    }
}


private protocol EmptyMetadata: MetadataDeclaration {
    associatedtype Key = Never
}

private extension EmptyMetadata {
    var value: Key.Value {
        fatalError("Can't access the value of an empty Metadata Declaration!")
    }

    func accept(_ visitor: SyntaxTreeVisitor) {}
}

private struct EmptyComponentMetadata: ComponentOnlyMetadata, EmptyMetadata {}
private struct EmptyHandlerMetadata: HandlerMetadata, EmptyMetadata {}
private struct EmptyContentMetadata: ContentMetadata, EmptyMetadata {}
private struct EmptyWebServiceMetadata: WebServiceMetadata, EmptyMetadata {}
