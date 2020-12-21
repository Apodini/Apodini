//
//  AnyComponent.swift
//
//
//  Created by Paul Schmiedmayer on 7/10/20.
//



public struct AnyEndpointNode: EndpointNode, Visitable {
    public typealias Response = Never
    
    private let _visit: (SyntaxTreeVisitor) -> Void
    
    init<T: EndpointNode>(_ endpointNode: T) {
        _visit = endpointNode.visit
    }
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        _visit(visitor)
    }
}



public struct AnyEndpointProvidingNode: EndpointProvidingNode, Visitable {
    public typealias Content = Never
    
    private let _visit: (SyntaxTreeVisitor) -> Void
    
    init<T: EndpointProvidingNode>(_ endpointNode: T) {
        _visit = endpointNode.visit
    }
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        _visit(visitor)
    }
}

