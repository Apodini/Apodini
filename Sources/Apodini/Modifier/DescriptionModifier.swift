//
// Created by Lorena Schlesinger on 10.01.21.
//

struct DescriptionContextKey: OptionalContextKey {
    typealias Value = (String, String?)
}

public struct DescriptionModifier<H: Handler>: HandlerModifier {
    public let component: H
    let description: String
    let tag: String?

    init(_ component: H, description: String, tag: String? = nil) {
        self.component = component
        self.description = description
        self.tag = tag
    }
}

extension DescriptionModifier: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DescriptionContextKey.self, value: (description, tag), scope: .current)
        component.accept(visitor)
    }
}

extension Handler {
    /// A `description` modifier can be used to explicitly specify the `description` for the given `Handler`
    /// - Parameter description: The `description` that is used to for the handler
    /// - Parameter tag: The  `tag` that is used for logical grouping of operations within the API documentation
    /// - Returns: The modified `Handler` with a specified `description` and the `tag`
    public func description(_ description: String, _ tag: String? = nil) -> DescriptionModifier<Self> {
        DescriptionModifier(self, description: description, tag: tag)
    }
}
