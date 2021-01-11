//
//  Context.swift
//  
//
//  Created by Paul Schmiedmayer on 11/3/20.
//


class Context {
    private let contextNode: ContextNode
    
    
    init(contextNode: ContextNode) {
        self.contextNode = contextNode
    }
    
    
    func get<C: ContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value {
        contextNode.getContextValue(for: contextKey)
    }

    func get<C: OptionalContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value? {
        contextNode.getContextValue(for: contextKey)
    }
}
