//
//  Modifier.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor


protocol Modifier: Component {
    associatedtype ModifiedComponent: Component
    
    
    var component: Self.ModifiedComponent { get }
}


extension Modifier {
    public func handle(_ request: Vapor.Request) -> EventLoopFuture<ModifiedComponent.Response> {
        component.handleInContext(of: request)
    }
}
