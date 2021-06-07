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


public struct AnyHandler: Handler, SyntaxTreeVisitable, VisitableHandler {
    public typealias Response = Never
    
    private let _accept: (SyntaxTreeVisitor) -> Void
    private let _handleraccept: (HandlerVisitor) throws -> Void
    
    init<H: Handler>(_ handler: H) {
        _accept = handler.accept
        _handleraccept = handler.accept
    }
    
    fileprivate init(accept: @escaping (SyntaxTreeVisitor) -> Void, handleraccept: @escaping (HandlerVisitor) throws -> Void) {
        self._accept = accept
        self._handleraccept = handleraccept
    }
    
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        _accept(visitor)
    }
    
    func accept(_ visitor: HandlerVisitor) throws {
        try _handleraccept(visitor)
    }
}

extension Handler {
    @_disfavoredOverload
    func accept(_ visitor: HandlerVisitor) throws {
        try visitor.visit(handler: self)
    }
}


protocol HandlerVisitor {
    func visit<H: Handler>(handler: H) throws
}

protocol VisitableHandler {
    func accept(_ visitor: HandlerVisitor) throws
}


public struct SomeHandler<R: ResponseTransformable>: SyntaxTreeVisitable, VisitableHandler {
    public typealias Response = R
    
    private let _accept: (SyntaxTreeVisitor) -> Void
    private let _handleraccept: (HandlerVisitor) throws -> Void
    
    public init<H: Handler>(_ handler: H) {
        _accept = handler.accept
        _handleraccept = handler.accept
    }
    
    var anyHandler: AnyHandler {
        AnyHandler(accept: self._accept, handleraccept: self._handleraccept)
    }
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        _accept(visitor)
    }
    
    func accept(_ visitor: HandlerVisitor) throws {
        try _handleraccept(visitor)
    }
}
