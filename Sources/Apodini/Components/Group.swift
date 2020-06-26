//
//  Group.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


public struct Group<Content: Component>: Component, Visitable {
    private let pathComponents: [PathComponent]
    public let content: Content
    
    
    public init(_ pathComponents: PathComponent...,
         @ComponentBuilder content: () -> Content) {
        self.pathComponents = pathComponents
        self.content = content()
    }
    
    
    public func visit<V>(_ visitor: inout V) where V: Visitor {
        visitor.enter(self)
        visitor.addContext(label: "pathComponents", pathComponents)
        content.visit(&visitor)
        visitor.exit(self)
    }
}
