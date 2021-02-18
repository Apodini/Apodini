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


struct ExplicitlyIdentifiedHandlerIdentifierValueContextKey: Apodini.OptionalContextKey {
    typealias Value = AnyHandlerIdentifier
}


public struct ExplicitlyIdentifiedHandlerModifier<Content: Handler>: HandlerModifier, SyntaxTreeVisitable {
    public let component: Content
    let identifier: AnyHandlerIdentifier
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(ExplicitlyIdentifiedHandlerIdentifierValueContextKey.self, value: identifier, scope: .current)
        component.accept(visitor)
    }
}


extension Handler {
    public func identified(by identifier: String) -> ExplicitlyIdentifiedHandlerModifier<Self> {
        ExplicitlyIdentifiedHandlerModifier(component: self, identifier: AnyHandlerIdentifier(identifier))
    }
    
    public func identified(by identifier: AnyHandlerIdentifier) -> ExplicitlyIdentifiedHandlerModifier<Self> {
        ExplicitlyIdentifiedHandlerModifier(component: self, identifier: identifier)
    }
}

