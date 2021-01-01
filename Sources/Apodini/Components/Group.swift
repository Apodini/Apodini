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


public struct Group<Content: Component>: Component, SyntaxTreeVisitable {
    private let pathComponents: [PathComponent]
    public let content: Content
    
    public init(_ pathComponents: PathComponent..., @ComponentBuilder content: () -> Content) {
        self.pathComponents = pathComponents
        self.content = content()
    }
    
    func accept(_ visitor: SyntaxTreeVisitor) {
        let contentIsNotTupleComponent = !String(describing: type(of: content)).hasPrefix("TupleComponent<")
        if contentIsNotTupleComponent {
            visitor.enterContent()
            visitor.enterComponentContext()
        }
        visitor.addContext(PathComponentContextKey.self, value: pathComponents, scope: .environment)
        content.accept(visitor)
        if contentIsNotTupleComponent {
            visitor.exitComponentContext()
            visitor.exitContent()
        }
    }
}
