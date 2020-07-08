//
//  Text.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor


public struct Text: Component, Visitable {
    public typealias Response = String
    
    private let text: String
    
    
    public init(_ text: String) {
        self.text = text
    }
    
    public func handle() -> EventLoopFuture<String> {
        fatalError("Not implemented")
    }
    
    public func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.register(component: self)
    }
}
