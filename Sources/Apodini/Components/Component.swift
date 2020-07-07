//
//  Component.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor


public protocol Component: Visitable {
    associatedtype Content: Component = Never
    associatedtype Response: ResponseEncodable = Never
    
    var content: Self.Content { get }
    
    func handle(_ request: Vapor.Request) -> EventLoopFuture<Self.Response>
}


public protocol ComponentCollection: Component { }


extension Component {
    func handleInContext(of request: Vapor.Request) -> EventLoopFuture<Self.Response> {
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
