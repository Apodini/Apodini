//
// Created by Andreas Bauer on 16.01.21.
//

struct DefaultRelationshipContextKey: OptionalContextKey {
    // This OptionalContextKey doesn't carry any additional context.
    // We only need to check if the context key exists on a Endpoint
    typealias Value = Void
}

public struct DefaultRelationshipModifier<H: HandlerDefiningComponent>: HandlerModifier {
    public let component: H

    init(_ component: H) {
        self.component = component
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DefaultRelationshipContextKey.self, value: (), scope: .current)
    }
}

extension HandlerDefiningComponent {
    /// A `defaultRelationship` modifier can be used to mark the return type - the `Content` type -
    /// as "default" for Relationships inferred from type information.
    ///
    /// - Returns: The modified `HandlerDefiningComponent` with the `Content` being marked as default.
    public func defaultRelationship() -> DefaultRelationshipModifier<Self> {
        DefaultRelationshipModifier(self)
    }
}
