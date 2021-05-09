//
//  Context.swift
//  
//
//  Created by Paul Schmiedmayer on 11/3/20.
//


/// Defines some sort of `Context` for a given representation (like `Endpoint`).
/// A `Context` holds a collection of values for predefined `ContextKey`s or `OptionalContextKey`s.
public class Context: KnowledgeSource {
    private let contextNode: ContextNode
    
    init(contextNode: ContextNode) {
        self.contextNode = contextNode
    }
    
    public required init<B>(_ blackboard: B) throws where B: Blackboard {
        self.contextNode = blackboard[AnyEndpointSource.self].context.contextNode
    }

    /// Retrieves the value for a given `ContextKey`.
    /// - Parameter contextKey: The `ContextKey` to retrieve the value for.
    /// - Returns: Returns the stored value or the `ContextKey.defaultValue` if it does not exist on the given `Context`.
    public func get<C: ContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value {
        contextNode.getContextValue(for: contextKey)
    }

    /// Retrieves the value for a given `OptionalContextKey`.
    /// - Parameter contextKey: The `OptionalContextKey` to retrieve the value for.
    /// - Returns: Returns the stored value or `nil` if it does not exist on the given `Context`.
    public func get<C: OptionalContextKey>(valueFor contextKey: C.Type = C.self) -> C.Value? {
        contextNode.getContextValue(for: contextKey)
    }
}
