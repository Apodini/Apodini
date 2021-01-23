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
