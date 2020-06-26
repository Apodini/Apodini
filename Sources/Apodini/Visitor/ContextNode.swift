//
//  ContextNode.swift
//  
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


class ContextNode {
    private var nodeOnlyContext: [ObjectIdentifier: Any] = [:]
    let nodeLink: ContextNode?
    private var context: [ObjectIdentifier: Any] = [:]
    
    
    init(nodeLink: ContextNode? = nil) {
        self.nodeLink = nodeLink
    }
    
    
    func getContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value {
        getNodeOnlyContextValue(for: contextKey)
            ?? getGlobalContextValue(for: contextKey)
            ?? C.defaultValue
    }
    
    private func getNodeOnlyContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value? {
        nodeOnlyContext[ObjectIdentifier(contextKey)] as? C.Value
    }
    
    private func getGlobalContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value? {
        if let localContextValue = context[ObjectIdentifier(contextKey)] as? C.Value {
            return localContextValue
        }
        
        return nodeLink?.getGlobalContextValue(for: contextKey)
    }
    
    func addContext<C: ContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        var newValue = getContextValue(for: C.self)
        C.reduce(value: &newValue) {
            value
        }
        
        switch scope {
        case .nextComponent:
            nodeOnlyContext[ObjectIdentifier(contextKey)] = newValue
        case .environment:
            context[ObjectIdentifier(contextKey)] = newValue
        }
    }
    
    func newContextNode() -> ContextNode {
        ContextNode(nodeLink: self)
    }
    
    func removeCurrentNodeContext() {
        nodeOnlyContext = [:]
    }
}
