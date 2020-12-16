//
//  Modifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor



protocol AnyModifier {
    var modifiedValue: Any { get }
}


extension AnyModifier {
    func anyModifier_visit_defaultImpl(_ visitor: SyntaxTreeVisitor) throws {
        try visitor.unsafeVisitAny(modifiedValue)
    }
}










protocol EndpointModifier: EndpointNode {
    associatedtype ModifiedEndpoint: EndpointNode
    
    var endpoint: ModifiedEndpoint { get }
}


//protocol Modifier {
//    associatedtype ModifiedComponent
//
//    var component: Self.ModifiedComponent { get }
//}


extension EndpointModifier {
    /// A `Modifier`'s handle method should never be called!
    public func handle() -> Self.ModifiedEndpoint.Response {
        fatalError("A Modifier's handle method should never be called!")
    }
    
    public var __endpointId: Self.ModifiedEndpoint.EndpointIdentifier { endpoint.__endpointId }
    
    public var outgoingDependencies: Set<AnyEndpointIdentifier> { ModifiedEndpoint.outgoingDependencies }
}







protocol EndpointProvidingNodeModifier: EndpointProvidingNode {
    associatedtype ModifiedEndpointProvider: EndpointProvidingNode
    
    var content: ModifiedEndpointProvider { get }
}
