//
//  IdentifiableHandler.swift
//  
//
//  Created by Paul Schmiedmayer on 1/11/21.
//


/// A `Handler` which can be uniquely identified
public protocol IdentifiableHandler: Handler {
    /// The type of this handler's identifier
    associatedtype HandlerIdentifier: AnyHandlerIdentifier
    
    /// This handler's identifier
    var handlerId: HandlerIdentifier { get }
}


/// The `ContextKey` storing an DSL-specified explicit handler identifier
struct ExplicitHandlerIdentifierContextKey: Apodini.OptionalContextKey {
    typealias Value = AnyHandlerIdentifier
}


public struct ExplicitlyIdentifiedHandlerModifier<Content: HandlerDefiningComponent>: HandlerModifier {
    public let component: Content
    let identifier: AnyHandlerIdentifier

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(ExplicitHandlerIdentifierContextKey.self, value: identifier, scope: .current)
    }
}


extension HandlerDefiningComponent {
    /// Attach an identifier to this handler
    public func identified(by identifier: String) -> ExplicitlyIdentifiedHandlerModifier<Self> {
        ExplicitlyIdentifiedHandlerModifier(component: self, identifier: AnyHandlerIdentifier(identifier))
    }
    
    /// Attach an identifier to this handler
    public func identified(by identifier: AnyHandlerIdentifier) -> ExplicitlyIdentifiedHandlerModifier<Self> {
        ExplicitlyIdentifiedHandlerModifier(component: self, identifier: identifier)
    }
}
