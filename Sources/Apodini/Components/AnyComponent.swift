//
//  AnyComponent.swift
//  
//
//  Created by Paul Schmiedmayer on 7/10/20.
//


public struct AnyComponent: Component {
    private let _visit: (_ visitor: SyntaxTreeVisitor) -> Void
    
    
    init<C: Component>(_ component: C) {
        self._visit = component.visit
    }
}

// MARK: Syntax Tree Visitor
extension AnyComponent: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        _visit(visitor)
    }
}
