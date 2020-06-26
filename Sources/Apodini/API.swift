//
//  API.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


public class API<Content: Component>: Component {
    let version: Int
    public let content: Content
    
    
    public init(version: Int, @ComponentBuilder content: () -> Content) {
        self.version = version
        self.content = content()
    }
    
    
    public func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.enter(self)
        visitor.addContext(label: "version", version)
        content.visit(&visitor)
        visitor.exit(self)
    }
}
