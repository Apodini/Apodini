//
//  EndpointInstance.swift
//  
//
//  Created by Max Obermeier on 14.01.21.
//

import Foundation


struct EndpointInstance<H: Handler> {
    let endpoint: Endpoint<H>
    
    let handler: H
    
    let guards: [AnyGuard]
    let responseTransformers: [AnyResponseTransformer]
    
    init(from endpoint: Endpoint<H>, notifying callback: (() -> Void)? = nil) {
        self.endpoint = endpoint
        
        var handler = endpoint.handler
        
        // ObservedObject
        
//        _ = handler.collectObservedObjects().map { observedObject in
//            observedObject.valueDidChange = callback
//        }
        
        
        // State
        
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
    
