//
//  Group.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

struct PathComponentContextKey: ContextKey {
    static var defaultValue: [PathComponent] = []
    
    static func reduce(value: inout [PathComponent], nextValue: () -> [PathComponent]) {
        value.append(contentsOf: nextValue())
    }
}


public struct Group<Content: Component>: ComponentCollection {
    private let pathComponents: [PathComponent]
    public let content: Content
    
    
    public init(_ pathComponents: PathComponent...,
         @ComponentBuilder content: () -> Content) {
        self.pathComponents = pathComponents
        self.content = content()
    }
}


extension Group: Visitable {
    func visit(_ visitor: Visitor) {
        visitor.enter(collection: self)
        visitor.addContext(PathComponentContextKey.self, value: pathComponents, scope: .environment)
        content.visit(visitor)
        visitor.exit(collection: self)
    }
}
