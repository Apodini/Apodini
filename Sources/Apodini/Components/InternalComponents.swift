//
//  InternalComponents.swift
//  Apodini
//
//  Created by Lukas Kollmer on 2020-12-17.
//



struct _WrappedEndpoint<Endpoint: EndpointNode>: EndpointProvidingNode, Visitable {
    let endpoint: Endpoint
    var content: Never { fatalError() }
    
    init(_ endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    func visit(_ visitor: SyntaxTreeVisitor) {
        endpoint.visit(visitor)
    }
}
