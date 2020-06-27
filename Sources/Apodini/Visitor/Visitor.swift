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


open class Visitor {
    private(set) var currentNode: ContextNode = ContextNode()
    
    
    public init() {}
    
    
    open func enter<C: ComponentCollection>(collection: C) {
        currentNode = currentNode.newContextNode()
    }
    
    open func addContext<C: ContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        currentNode.addContext(contextKey, value: value, scope: scope)
    }
    
    public func getContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value {
        currentNode.getContextValue(for: C.self)
    }
    
    open func register<C: Component>(component: C) { }
    
    public func removeCurrentNodeContext() {
        currentNode.removeCurrentNodeContext()
    }
    
    open func exit<C: ComponentCollection>(collection: C) {
        if let parentNode = currentNode.nodeLink {
            currentNode = parentNode
        }
    }
}


public protocol Visitable {
    func visit<V: Visitor>(_ visitor: inout V)
}
