//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
public struct PathComponentContextKey: ContextKey {
    public typealias Value = [PathComponent]
    public static var defaultValue: [PathComponent] = []
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
