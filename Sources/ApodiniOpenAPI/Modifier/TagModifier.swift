//
// Created by Lorena Schlesinger on 10.01.21.
//

import Apodini

public struct TagContextKey: OptionalContextKey {
    public typealias Value = [String]
}

public struct TagModifier<H: Handler>: HandlerModifier {
    public let component: H
    let tags: [String]
    
    init(_ component: H, tags: [String]) {
        self.component = component
        self.tags = tags
    }
}

extension TagModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(TagContextKey.self, value: tags, scope: .current)
        component.accept(visitor)
    }
}

extension Handler {
    /// A `tag` modifier can be used to explicitly specify the `tags` for the given `Handler`
    /// - Parameter tags: Arbitrary amount of `tags` that are used for logical grouping of operations, e.g., within the API documentation
    /// - Returns: The modified `Handler` with specific `tags`
    public func tags(_ tags: String...) -> TagModifier<Self> {
        TagModifier(self, tags: tags)
    }
}
