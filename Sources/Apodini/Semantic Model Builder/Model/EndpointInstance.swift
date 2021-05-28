//
//  EndpointInstance.swift
//  
//
//  Created by Max Obermeier on 14.01.21.
//

import Foundation


struct EndpointInstance<H: Handler> {
    let endpoint: Endpoint<H>
    
    var handler: H
    
    let guards: [AnyGuard]
    let responseTransformers: [AnyResponseTransformer]
    
    init(from endpoint: Endpoint<H>) {
        self.endpoint = endpoint
        
        var handler = endpoint.handler
        
        activate(&handler)
        
        self.handler = handler
        
        self.guards = endpoint.guards.map { lazyGuard in
            var `guard` = lazyGuard()
            `guard`.activate()
            return `guard`
        }
        
        self.responseTransformers = endpoint.responseTransformers.map { lazyTransformer in
            var transformer = lazyTransformer()
            transformer.activate()
            return transformer
        }
    }
}
    
