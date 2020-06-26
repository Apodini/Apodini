//
//  Modifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO


protocol Modifier: Component {
    associatedtype ModifiedComponent: Component
    
    
    var component: ModifiedComponent { get }
}


extension Modifier {
    public func handle(_ request: Request) -> EventLoopFuture<ModifiedComponent.Response> {
        component.executeInContext(of: request)
    }
}
