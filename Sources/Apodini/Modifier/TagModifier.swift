//
// Created by Lorena Schlesinger on 10.01.21.
//

struct TagContextKey: OptionalContextKey {
    typealias Value = [String]
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
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(TagContextKey.self, value: tags, scope: .current)
        component.accept(visitor)
    }
}

extension Handler {
    /// A `tag` modifier can be used to explicitly specify the `tags` for the given `Handler`
    /// - Parameter tags: The  `tag` that is used for logical grouping of operations within the API documentation
    /// - Returns: The modified `Handler` with a tagged with specific `tags`
    public func tags(_ tags: String...) -> TagModifier<Self> {
        TagModifier(self, tags: tags)
    }
}
