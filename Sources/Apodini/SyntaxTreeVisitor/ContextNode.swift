//
//  ContextNode.swift
//  
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Foundation
import ApodiniUtils

class ContextNode {
    private var nodeOnlyContext: [ObjectIdentifier: Any] = [:]
    let parentContextNode: ContextNode?
    private var context: [ObjectIdentifier: Any] = [:]
    
    
    init(nodeLink: ContextNode? = nil) {
        self.parentContextNode = nodeLink
    }
    
    func copy() -> ContextNode {
        let newContextNode = ContextNode(nodeLink: parentContextNode)
        newContextNode.nodeOnlyContext = nodeOnlyContext
        newContextNode.context = context
        return newContextNode
    }
    
    func getContextValue<C: ContextKey>(for contextKey: C.Type = C.self) -> C.Value {
        getNodeOnlyContextValue(for: contextKey)
            ?? getGlobalContextValue(for: contextKey)
            ?? C.defaultValue
    }

    func getContextValue<C: OptionalContextKey>(for contextKey: C.Type = C.self) -> C.Value? {
        getNodeOnlyContextValue(for: contextKey)
            ?? getGlobalContextValue(for: contextKey)
    }
    
    private func getNodeOnlyContextValue<C: OptionalContextKey>(for contextKey: C.Type = C.self) -> C.Value? {
        nodeOnlyContext[ObjectIdentifier(contextKey)] as? C.Value
    }
    
    private func getNodeContextValue<C: OptionalContextKey>(for contextKey: C.Type = C.self) -> C.Value? {
        context[ObjectIdentifier(contextKey)] as? C.Value
    }
    
    private func getGlobalContextValue<C: OptionalContextKey>(for contextKey: C.Type = C.self) -> C.Value? {
        getNodeContextValue(for: contextKey) ?? parentContextNode?.getGlobalContextValue(for: contextKey)
    }
    
    func addContext<C: OptionalContextKey>(_ contextKey: C.Type = C.self, value: C.Value, scope: Scope) {
        let newValue: C.Value

        if isOptional(C.Value.self) {
            fatalError("""
                       The `Value` type of a `ContextKey` or `OptionalContextKey` must not be a `Optional` type.
                       Found \(C.Value.self) as `Value` type for key \(C.self).
                       """)
        }
        
        if let currentLocalValue = getNodeOnlyContextValue(for: C.self) ?? getNodeContextValue(for: C.self) {
            // Already existing values in the ContextNode have a higher priority as the modifier for a
            // Component are parsed in a reverse order:
            //
            // Component()
            //     .modifier(1) // Parsed second
            //     .modifier(2) // Parsed first, stored in `nodeOnlyContext` or `context`
            //
            // As we expect that Components is using `2` based on the modifiers we pass the `value` as the existing
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
            //         .modifier(2) // We expect Component to use `2`
            // }.modifier(1)
            C.reduce(value: &contextValue) {
                value
            }
            newValue = contextValue
        } else {
            // we need to check if `OptionalContextKey` is type of `ContextKey`
            // aka if the `ContextKey provides a default value. Because if it provides a defaultValue
            // we need to call `reduce(...)` with it before inserting.

            // if defaultValue is nil the contextKey didn't conform to `ContextKey` => doesn't have a default value
            if let contextKey = contextKey as? HasDefaultValue.Type {
                // the visitor above returns Any, thus we need to properly cast. I can't think of a scenario
                // where this can't go wrong, but that's what fatalErrors are for right?
                let defaultValue = contextKey.defaultValue
                if var defaultValue = defaultValue as? C.Value {
                    // If there is no value in the local ContextNode nor in the global context we use the default value
                    // as the old value and the new value as the newValue in the reduce function call.
                    C.reduce(value: &defaultValue) {
                        value
                    }
                    newValue = defaultValue
                } else {
                    fatalError("Failed to cast type of defaultValue \(type(of: defaultValue)) to expected Type of the ContextKey \(C.Value.self)")
                }
            } else {
                // we have a OptionalContextKey, there is no defaultValue with can reduce into
                // thus we just store the supplied value
                newValue = value
            }
        }
        
        switch scope {
        case .current:
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
