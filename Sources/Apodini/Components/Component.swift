//
//  Component.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor


public protocol Component {
    associatedtype Content: Component = Never
    associatedtype Response: ResponseEncodable = Never
    
    @ComponentBuilder var content: Self.Content { get }
    
    func handle() -> EventLoopFuture<Self.Response>
    
    func handleInContext(of request: Vapor.Request) -> EventLoopFuture<Self.Response>
}

extension Component where Self.Content: Visitable {
    func visit<V: Visitor>(_ visitor: inout V) {
        content.visit(&visitor)
    }
}

extension Component {
    public func handleInContext(of request: Vapor.Request) -> EventLoopFuture<Self.Response> {
        request.enterRequestContext(with: self) { component in
            component.handle()
        }
    }
}


protocol _Component: Component, Visitable {
    
}


extension _Component {
    func visit<V: Visitor>(_ visitor: inout V) {
        if Self.Content.self != Never.self, let visitableContent = content as? Visitable {
            visitableContent.visit(&visitor)
        } else {
            visitor.register(component: self)
        }
    }
}


public protocol ComponentCollection: Component { }


protocol _ComponentCollection: ComponentCollection, _Component { }


extension _ComponentCollection {
    func visit<V>(_ visitor: inout V) where V: Visitor {
        visitor.enter(collection: self)
        if let visitableContent = content as? Visitable {
            visitableContent.visit(&visitor)
        }
        visitor.exit(collection: self)
    }
}
