//
//  Group.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//



struct PathComponentContextKey: ContextKey {
    static var defaultValue: [PathComponent] = []

    static func reduce(value: inout [PathComponent], nextValue: () -> [PathComponent]) {
        value.append(contentsOf: nextValue())
    }
}




protocol _GroupBase: Visitable {
    var pathComponents: [PathComponent] { get }
}



/// A group which contains a single endpoint
struct _GroupLeafEndpoint<Content: EndpointNode>: _GroupBase, EndpointProvidingNode {
    let pathComponents: [PathComponent]
    let endpoint: Content
    
    var content: Never { fatalError() }
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        visitor.enterCollectionItem()
        visitor.addContext(PathComponentContextKey.self, value: pathComponents, scope: .environment)
        endpoint.visit(visitor)
        visitor.exitCollectionItem()
    }
}




/// A group whoch contains further content, but no endpoint
struct _GroupWithoutEndpoint<Content: EndpointProvidingNode>: _GroupBase, EndpointProvidingNode {
    let pathComponents: [PathComponent]
    let content: Content
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        visitor.enterCollectionItem()
        visitor.addContext(PathComponentContextKey.self, value: pathComponents, scope: .environment)
        content.visit(visitor)
        visitor.exitCollectionItem()
    }
}


/// A group which contains both an endpoint as well as further content
struct _GroupWithEndpoint<Endpoint: EndpointNode, Content: EndpointProvidingNode>: _GroupBase, EndpointProvidingNode {
    let pathComponents: [PathComponent]
    let endpoint: Endpoint
    let content: Content
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        visitor.enterCollectionItem()
        visitor.addContext(PathComponentContextKey.self, value: pathComponents, scope: .environment)
        content.visit(visitor)
        endpoint.visit(visitor)
        visitor.exitCollectionItem()
    }
}





struct _GroupWithEndpointInitializationHelper<Endpoint: EndpointNode, Content: EndpointProvidingNode> {
    let endpoint: Endpoint
    let content: Content
}




struct _WrappedEndpoint<Endpoint: EndpointNode>: EndpointProvidingNode, Visitable {
    let endpoint: Endpoint
    var content: Never { fatalError() }
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        endpoint.visit(visitor)
    }
}





func Group<Content: EndpointProvidingNode>(_ pathComponents: PathComponent..., @EndpointProvidingNodeBuilder content: () -> Content) -> some EndpointProvidingNode {
    return _GroupWithoutEndpoint(pathComponents: pathComponents, content: content())
}



func Group<Endpoint: EndpointNode, Content: EndpointProvidingNode>(
    _ pathComponents: PathComponent...,
    @EndpointAndContentBuilder content: () -> _GroupWithEndpointInitializationHelper<Endpoint, Content>
) -> some EndpointProvidingNode {
    let members = content()
    return _GroupWithEndpoint(pathComponents: pathComponents, endpoint: members.endpoint, content: members.content)
}





@_functionBuilder
enum EndpointAndContentBuilder {
    static func buildBlock<Endpoint: EndpointNode, Content: EndpointProvidingNode>(
        _ endpoint: Endpoint,
        _ content: Content
    ) -> _GroupWithEndpointInitializationHelper<Endpoint, Content> {
        return .init(endpoint: endpoint, content: content)
    }
    
    
    static func buildBlock<Content: EndpointProvidingNode, Endpoint: EndpointNode>(
        _ content: Content,
        _ endpoint: Endpoint
    ) -> _GroupWithEndpointInitializationHelper<Endpoint, Content> {
        return .init(endpoint: endpoint, content: content)
    }
}
