//
//  InternalComponents.swift
//  Apodini
//
//  Created by Lukas Kollmer on 2020-12-17.
//



struct _WrappedHandler<H: Handler>: Component, Visitable {
    public typealias Content = Never
    
    let handler: H
    
    init(_ handler: H) {
        self.handler = handler
    }
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        handler.visit(visitor)
    }
}
