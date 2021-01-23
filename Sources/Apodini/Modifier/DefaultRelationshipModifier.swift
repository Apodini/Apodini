//
// Created by Andreas Bauer on 16.01.21.
//

struct DefaultRelationshipContextKey: OptionalContextKey {
    // We really only need to check if the context key exists on a Endpoint
    // So the type is actually irrelevant, but Bool probably fits best?
    typealias Value = Bool
}

public struct DefaultRelationshipModifier<H: Handler>: HandlerModifier {
    public let component: H

    init(_ component: H) {
        self.component = component
    }
}

extension DefaultRelationshipModifier: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DefaultRelationshipContextKey.self, value: true, scope: .current)
        component.accept(visitor)
    }
}

extension Handler {
    /// A `defaultRelationship` modifier can be used to mark the return type - the `Content` type -
    /// as "default" for Relationships inferred from type information.
    ///
    /// - Returns: The modified `Handler` with the `Content` being marked as default.
    public func defaultRelationship() -> DefaultRelationshipModifier<Self> {
        DefaultRelationshipModifier(self)
    }
}
