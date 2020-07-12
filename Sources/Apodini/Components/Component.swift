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
    
    func handle() -> Self.Response
}


extension Component {
    func visit(_ visitor: Visitor) {
        visitContentOrRegisterComponentIfNotNever(visitor)
    }
    
    fileprivate func visitContentOrRegisterComponentIfNotNever(_ visitor: Visitor) {
        if let visitable = self as? Visitable {
            visitable.visit(visitor)
        } else if Self.Content.self != Never.self {
            content.visit(visitor)
        } else {
            visitor.register(component: self)
        }
    }
}

public protocol ComponentCollection: Component { }


extension ComponentCollection {
    func visit(_ visitor: Visitor) {
        visitor.enter(collection: self)
        visitContentOrRegisterComponentIfNotNever(visitor)
        visitor.exit(collection: self)
    }
}
