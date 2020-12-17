//
//  Component.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Runtime
import protocol Vapor.ResponseEncodable


// A node in the DSL which can handle requests
public protocol EndpointNode { // rename to EndpointComponent?
    associatedtype Response: ResponseEncodable
    associatedtype EndpointIdentifier: AnyEndpointIdentifier
    
    func handle() -> Response
    
    // underscored as to avoid clashes w/ potential parameters, or other custom properties of the conforming type
    var __endpointId: EndpointIdentifier { get }
    
    static var outgoingDependencies: Set<AnyEndpointIdentifier> { get }
}


extension EndpointNode {
    public static var outgoingDependencies: Set<AnyEndpointIdentifier> { [] }
}


extension EndpointNode where EndpointIdentifier == AnyEndpointIdentifier {
    public var __endpointId: EndpointIdentifier { .init(Self.self) }
}




// A node in the DSL which provides one or more endpoints
public protocol EndpointProvidingNode { // rename to Content?
    associatedtype Content: EndpointProvidingNode
    
    @EndpointProvidingNodeBuilder
    var content: Content { get }
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
