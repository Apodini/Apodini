//
//  Modifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//



protocol EndpointModifier: Handler {
    associatedtype ModifiedEndpoint: Handler
    
    var endpoint: ModifiedEndpoint { get }
}



extension EndpointModifier {
    /// A `Modifier`'s handle method should never be called!
    public func handle() -> Self.ModifiedEndpoint.Response {
        fatalError("A Modifier's handle method should never be called!")
    }
    
    public var __endpointId: Self.ModifiedEndpoint.EndpointIdentifier { endpoint.__endpointId }
    
    public var outgoingDependencies: Set<AnyEndpointIdentifier> { ModifiedEndpoint.outgoingDependencies }
}




protocol EndpointProvidingNodeModifier: Component {
    associatedtype ModifiedEndpointProvider: Component
    
    var content: ModifiedEndpointProvider { get }
}
