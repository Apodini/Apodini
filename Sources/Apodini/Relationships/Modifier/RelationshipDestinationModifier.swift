//
// Created by Andreas Bauer on 16.01.21.
//

public struct RelationshipDestinationContextKey: ContextKey {
    public static var defaultValue: [Relationship] = []

    public static func reduce(value: inout [Relationship], nextValue: () -> [Relationship]) {
        value.append(contentsOf: nextValue())
    }
}

public struct RelationshipDestinationModifier<H: Handler>: HandlerModifier {
    public let component: H
    let relationship: Relationship

    init(_ component: H, _ relationship: Relationship) {
        self.component = component
        self.relationship = relationship
    }
}

extension RelationshipDestinationModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(RelationshipDestinationContextKey.self, value: [relationship], scope: .current)
        component.accept(visitor)
    }
}

extension Handler {
    /// A `destination(of:)` modifier can be used to mark this `Handler`
    /// as the destination for the given `Relationship` instance.
    ///
    /// - Parameter relationship: The `Relationship` instance for which this `Handler` should be the destination for.
    /// - Returns: The modified `Handler` being marked as the destination for the `Relationship` instance.
    public func destination(of relationship: Relationship) -> RelationshipDestinationModifier<Self> {
        RelationshipDestinationModifier(self, relationship)
    }
}
