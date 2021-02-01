//
//  AnyComponent.swift
//
//
//  Created by Paul Schmiedmayer on 7/10/20.
//


public struct AnyComponent: Component, SyntaxTreeVisitable {
    public typealias Content = Never
    
    private let _accept: (SyntaxTreeVisitor) -> Void
    
    init<C: Component>(_ component: C) {
        _accept = component.accept
    }
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        _accept(visitor)
    }
}


public struct AnyHandler: Handler, SyntaxTreeVisitable {
    public typealias Response = Never
    
    private let _accept: (SyntaxTreeVisitor) -> Void
    
    init<H: Handler>(_ handler: H) {
        _accept = handler.accept
    }
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        _accept(visitor)
    }
}
