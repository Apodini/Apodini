//
//  Visitor.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

public enum Scope {
    case nextComponent
    case environment
}


public class Visitor {
    private(set) var currentNode: ContextNode = ContextNode()
    
    func enter<C: ComponentCollection>(collection: C) {
        currentNode = currentNode.newContextNode()
    }
    
    func addContext<C: ContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        currentNode.addContext(contextKey, value: value, scope: scope)
    }
    
    func register<C: Component>(component: C) { }
    
    func removeCurrentNodeContext() {
        currentNode.removeCurrentNodeContext()
    }
    
    func exit<C: ComponentCollection>(collection: C) {
        if let parentNode = currentNode.nodeLink {
            currentNode = parentNode
        }
    }
}


public protocol Visitable {
    func visit<V: Visitor>(_ visitor: inout V)
}
