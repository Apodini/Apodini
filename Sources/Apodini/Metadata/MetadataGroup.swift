//
// Created by Andreas Bauer on 16.05.21.
//

public protocol AnyMetadataGroup: AnyMetadata {}

public protocol HandlerMetadataGroup: AnyMetadataGroup, AnyHandlerMetadata {
    @MetadataBuilder
    var content: AnyHandlerMetadata { get }
}

extension HandlerMetadataGroup {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}

public protocol ComponentOnlyMetadataGroup: AnyMetadataGroup, AnyComponentOnlyMetadata, ComponentMetadataNamespace {
    @MetadataBuilder
    var content: AnyComponentOnlyMetadata { get }
}

extension ComponentOnlyMetadataGroup {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}

public protocol WebServiceMetadataGroup: AnyMetadataGroup, AnyWebServiceMetadata {
    @MetadataBuilder
    var content: AnyWebServiceMetadata { get }
}

extension WebServiceMetadataGroup {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}

// TODO docs: ComponentMetadataGroup is not similar to ComponentMetadataDefinition, that it doesn't inherit from
public protocol ComponentMetadataGroup: AnyMetadataGroup, AnyComponentMetadata, ComponentMetadataNamespace {
    @ComponentMetadataBuilder
    var content: AnyComponentMetadata { get }
}

extension ComponentMetadataGroup {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}

public protocol ContentMetadataGroup: AnyMetadataGroup, AnyContentMetadata {
    @MetadataBuilder
    var content: AnyContentMetadata { get }
}

extension ContentMetadataGroup {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        content.accept(visitor)
    }
}


// TODO don't really like the "Collect" name; think of something else, which doesn't collide with "Group"
//    => At the end it should match the e.g. "HandlerMetadataGroup" names, cause they are intended to be used
//       by the user as well
extension ComponentMetadataNamespace {
    public typealias Collect = StandardComponentMetadataGroup
}

extension HandlerMetadataNamespace {
    public typealias Collect = StandardHandlerMetadataGroup
}

extension WebServiceMetadataNamespace {
    public typealias Collect = StandardWebServiceMetadataGroup
}

extension ContentMetadataNamespace {
    public typealias Collect = StandardContentMetadataGroup
}


public struct StandardHandlerMetadataGroup: HandlerMetadataGroup {
    public var content: AnyHandlerMetadata

    public init(@MetadataBuilder content: () -> AnyHandlerMetadata) {
        self.content = content()
    }
}

public struct StandardComponentMetadataGroup: ComponentOnlyMetadataGroup {
    public var content: AnyComponentOnlyMetadata
    
    public init(@MetadataBuilder content: () -> AnyComponentOnlyMetadata) {
        self.content = content()
    }
}

public struct StandardWebServiceMetadataGroup: WebServiceMetadataGroup {
    public var content: AnyWebServiceMetadata
    
    public init(@MetadataBuilder content: () -> AnyWebServiceMetadata) {
        self.content = content()
    }
}

public struct StandardContentMetadataGroup: ContentMetadataGroup {
    public var content: AnyContentMetadata
    
    public init(@MetadataBuilder content: () -> AnyContentMetadata) {
        self.content = content()
    }
}
