//
//  Group.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

public struct PathComponentContextKey: ContextKey {
    public static var defaultValue: [PathComponent] = []

    public static func reduce(value: inout [PathComponent], nextValue: () -> [PathComponent]) {
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

    public init(@PathComponentBuilder path: () -> [PathComponent], @ComponentBuilder content: () -> Content) {
        self.pathComponents = path()
        self.content = content()
    }
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.enterContent {
            visitor.enterComponentContext {
                var component = pathComponents
                component.markEnd()
                visitor.addContext(PathComponentContextKey.self, value: component, scope: .environment)

                if Content.self != Never.self {
                    content.accept(visitor)
                }
            }
        }
    }
}
