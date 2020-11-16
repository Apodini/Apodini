//
//  ContextNode.swift
//  
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


class ContextNode {
    private var nodeOnlyContext: [ObjectIdentifier: Any] = [:]
    let parentContextNode: ContextNode?
    private var context: [ObjectIdentifier: Any] = [:]
    
    
    init(nodeLink: ContextNode? = nil) {
        self.parentContextNode = nodeLink
    }
    
    func copy() -> ContextNode {
        let newContextNode = ContextNode(nodeLink: parentContextNode?.copy())
        newContextNode.nodeOnlyContext = nodeOnlyContext
        newContextNode.context = context
        return newContextNode
    }
    
    func getContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value {
        getNodeOnlyContextValue(for: contextKey)
            ?? getGlobalContextValue(for: contextKey)
            ?? C.defaultValue
    }
    
    private func getNodeOnlyContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value? {
        nodeOnlyContext[ObjectIdentifier(contextKey)] as? C.Value
    }
    
    private func getNodeContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value? {
        context[ObjectIdentifier(contextKey)] as? C.Value
    }
    
    private func getGlobalContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value? {
        getNodeContextValue(for: contextKey) ?? parentContextNode?.getGlobalContextValue(for: contextKey)
    }
    
    func addContext<C: ContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        var newValue: C.Value
        
        if let currentLocalValue = getNodeOnlyContextValue(for: C.self) ?? getNodeContextValue(for: C.self) {
            // Already existing values in the ContextNode have a higher priority as the modifier for a
            // Component are parsed in a reverse order:
            //
            // Component()
            //     .modifer(1) // Parsed second
            //     .modifer(2) // Parsed first, stored in `nodeOnlyContext` or `context`
            //
            // As we expect that Components is using `2` based on the modifers we pass the `value` as the existing
            // value and `currentLocalValue` as the new value to take advantage of the reduce function.
            var value = value
            C.reduce(value: &value) {
                currentLocalValue
            }
            newValue = value
        } else if var contextValue = getGlobalContextValue(for: C.self) {
            // If the context does not appear in the local ContextNode but in the context of a parent node we
            // assign the new value a higher priority and therefore pass it as the newValue in the reduce function.
            // Example:
            // Group {
            //     Component()
            //         .modifer(2) // We expect Component to use `2`
            // }.modifer(1)
            C.reduce(value: &contextValue) {
                value
            }
            newValue = contextValue
        } else {
            // If there is no value in the local ContextNode nor in the global context we use the default value
            // as the old value and the new value as the newValue in the reduce function call.
            var defaultValue = C.defaultValue
            C.reduce(value: &defaultValue) {
                value
            }
            newValue = defaultValue
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
    
    /// You **MUST** call this method once you are finished registering your component to reset the
    /// `ContextNode`'s state for the next `Component`.
    func resetContextNode() {
        nodeOnlyContext = [:]
        context = [:]
    }
}
