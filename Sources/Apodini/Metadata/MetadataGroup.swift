//
// Created by Andreas Bauer on 16.05.21.
//

public protocol MetadataGroup: AnyMetadata {
    var content: AnyMetadata { get }
}

public extension MetadataGroup {
    typealias Key = Never // groups don't expose data themselves, See `KeyedMetadata`
    var value: Never.Value {
        fatalError("Cannot access the value of a Metadata Group")
    }

    func acceptVisitor(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}


public struct ComponentMetadataGroup: MetadataGroup, ComponentOnlyMetadata {
    public var content: AnyMetadata
    
    public init(@MetadataContainerBuilder container: () -> ComponentMetadataContainer) {
        self.content = container().content
    }
}

public struct HandlerMetadataGroup: MetadataGroup, HandlerMetadata {
    public var content: AnyMetadata
    
    public init(@MetadataContainerBuilder container: () -> HandlerMetadataContainer) {
        self.content = container().content
    }
}

public struct WebServiceMetadataGroup: MetadataGroup, WebServiceMetadata {
    public var content: AnyMetadata
    
    public init(@MetadataContainerBuilder container: () -> WebServiceMetadataContainer) {
        self.content = container().content
    }
}

public struct ContentMetadataGroup: MetadataGroup, ContentMetadata {
    public var content: AnyMetadata
    
    public init(@MetadataContainerBuilder container: () -> ContentMetadataContainer) {
        self.content = container().content
    }
}

// TODO don't really like the "Collect" name; think of something else, which doesn't collide with "Group"
//    => Maybe also then adjust XXXXMetadataGroup names
extension ComponentMetadataScope {
    public typealias Collect = ComponentMetadataGroup
}
extension HandlerMetadataScope {
    public typealias Collect = HandlerMetadataGroup
}
extension WebServiceMetadataScope {
    public typealias Collect = WebServiceMetadataGroup
}
extension ContentMetadataScope {
    public typealias Collect = ContentMetadataGroup
}
