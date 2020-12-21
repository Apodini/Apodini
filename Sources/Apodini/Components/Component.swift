//
//  Component.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
@_implementationOnly import Runtime



/// A `Component` is the central building block of  Apodini. Each component handles a specific functionality of the Apodini web service.
///
/// A `Component` either has a `handle` function that is called when a request reaches the `Component` or consists of different other components as described by the `content` property.
public protocol EndpointProvidingNode {
    /// The type of `Component` this `Component` is made out of if the component is a composition of multiple subcomponents.
    associatedtype Content: EndpointProvidingNode
    
    /// Different other `Component`s that are composed to describe the functionality of the`Component`
    @EndpointProvidingNodeBuilder
    var content: Content { get }
}



public protocol EndpointNode {
    /// The type that is returned from the `handle` method when the component handles a request. The return type of the `handle` method is encoded into the response send out to the client.
    associatedtype Response: Encodable
    /// The type of this handler's identifier
    associatedtype EndpointIdentifier: AnyEndpointIdentifier

    func handle() -> Response
    
    // underscored as to avoid clashes w/ potential parameters, or other custom properties of the conforming type
    var __endpointId: EndpointIdentifier { get }
    
    /// This component's set of outgoing dependencies
    static var outgoingDependencies: Set<AnyEndpointIdentifier> { get }
}


/// Default implementation for components which don't specify any outgoing dependencies
extension EndpointNode {
    public static var outgoingDependencies: Set<AnyEndpointIdentifier> { [] }
}


/// Default implementation for components which don't specify an identifier
extension EndpointNode where EndpointIdentifier == AnyEndpointIdentifier {
    public var __endpointId: EndpointIdentifier { .init(Self.self) }
}






// MARK: Node + Visitor

extension EndpointNode {
    func visit(_ visitor: SyntaxTreeVisitor) {
        LKAssertTypeIsStruct(Self.self)
        if let visitable = self as? Visitable {
            visitable.visit(visitor)
        } else {
            visitor.register(component: self)
        }
    }
}


extension EndpointProvidingNode {
    func visit(_ visitor: SyntaxTreeVisitor) {
        LKAssertTypeIsStruct(Self.self)
        if let visitable = self as? Visitable {
            visitable.visit(visitor)
        } else {
            content.visit(visitor)
        }
    }
}



private func LKAssertTypeIsStruct<T>(_: T.Type) {
    guard let TI = try? typeInfo(of: T.self) else {
        fatalError("Unable to get type info for type '\(T.self)'")
    }
    precondition(TI.kind == .struct, "Node '\(TI.name)' must be a struct")
}
