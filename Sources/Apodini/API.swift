//
//  API.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

struct APIVersionContextKey: ContextKey {
    static var defaultValue: Int = 1
    
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = nextValue()
    }
}

public class API<Content: Component>: ComponentCollection {
    let version: Int
    public let content: Content
    
    
    public init(version: Int, @ComponentBuilder content: () -> Content) {
        self.version = version
        self.content = content()
    }
    
    
    public func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.enter(collection: self)
        visitor.addContext(APIVersionContextKey.self, value: version, scope: .environment)
        content.visit(&visitor)
        visitor.exit(collection: self)
    }
}
