//
//  Component.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO


public protocol Component: Visitable {
    associatedtype Content: Component
    associatedtype Response: Codable
    
    var content: Content { get }
    
    func handle(_ request: Request) -> EventLoopFuture<Response>
}


public protocol ComponentCollection: Component { }


extension Component {
    func handleInContext(of request: Request) -> EventLoopFuture<Response> {
        request.enterRequestContext(with: self) { component in
            component.handle(request)
        }
    }
}


extension Component where Content: Visitable {
    func visit<V: Visitor>(_ visitor: inout V) {
        content.visit(&visitor)
    }
}
