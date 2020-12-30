//
//  AnyComponent.swift
//
//
//  Created by Paul Schmiedmayer on 7/10/20.
//


public struct AnyComponent: Component, SyntaxTreeVisitable {
    public typealias Content = Never
    
    private let _visit: (SyntaxTreeVisitor) -> Void
    
    init<C: Component>(_ component: C) {
        _visit = component.visit
    }
    
    func accept(_ visitor: SyntaxTreeVisitor) {
        _visit(visitor)
    }
}


public struct AnyHandler: Handler, SyntaxTreeVisitable {
    public typealias Response = Never
    
    private let _visit: (SyntaxTreeVisitor) -> Void
    
    init<H: Handler>(_ handler: H) {
        _visit = handler.visit
    }
    
    func accept(_ visitor: SyntaxTreeVisitor) {
        _visit(visitor)
    }
}
