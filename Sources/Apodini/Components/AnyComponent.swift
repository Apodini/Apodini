//
//  AnyComponent.swift
//
//
//  Created by Paul Schmiedmayer on 7/10/20.
//


public struct AnyComponent: Component, Visitable {
    public typealias Content = Never
    
    private let _visit: (SyntaxTreeVisitor) -> Void
    
    init<T: Component>(_ Handler: T) {
        _visit = Handler.visit
    }
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        _visit(visitor)
    }
}


public struct AnyHandler: Handler, Visitable {
    public typealias Response = Never
    
    private let _visit: (SyntaxTreeVisitor) -> Void
    public let __endpointId: AnyEndpointIdentifier
    
    init<H: Handler>(_ handler: H) {
        _visit = handler.visit
        __endpointId = handler.__endpointId
    }
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        _visit(visitor)
    }
}
