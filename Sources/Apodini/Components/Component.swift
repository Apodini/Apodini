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
    
    func handle() -> EventLoopFuture<Self.Response>
    
    func handleInContext(of request: Vapor.Request) -> EventLoopFuture<Self.Response>
}


extension Component {
    public func handleInContext(of request: Vapor.Request) -> EventLoopFuture<Self.Response> {
        request.enterRequestContext(with: self) { component in
            component.handle()
        }
    }
}


public protocol ComponentCollection: Component { }


extension Component where Content: Visitable {
    func visit<V: Visitor>(_ visitor: inout V) {
        content.visit(&visitor)
    }
}
