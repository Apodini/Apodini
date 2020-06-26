//
//  Text.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO


public struct Text: Component, Visitable {
    private let text: String
    
    
    public init(_ text: String) {
        self.text = text
    }
    
    
    public func handle(_ request: Request) -> EventLoopFuture<String> {
        request.eventLoop.makeSucceededFuture(text)
    }
    
    public func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.register(component: self)
    }
}
