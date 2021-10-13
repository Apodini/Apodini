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
    
    init(from endpoint: Endpoint<H>) {
        self.endpoint = endpoint
        
        var handler = endpoint.handler
        
        activate(&handler)
        
        self.handler = handler
    }
}
    
