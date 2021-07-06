//
// Created by Andreas Bauer on 16.01.21.
//

public struct RelationshipSourceContextKey: ContextKey {
    public typealias Value = [Relationship]
    public static var defaultValue: [Relationship] = []
}

public struct RelationshipSourceModifier<H: Handler>: HandlerModifier {
    public let component: H
    let relationship: Relationship

    init(_ component: H, _ relationship: Relationship) {
        self.component = component
        self.relationship = relationship
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(RelationshipSourceContextKey.self, value: [relationship], scope: .current)
    }
}

extension Handler {
    /// A `relationship(to:)` modifier can be used to mark this `Handler`
    /// as the source for the given `Relationship` instance.
    ///
    /// - Parameter relationship: The `Relationship` instance for which this `Handler` should be the source for.
    /// - Returns: The modified `Handler` being marked as the source for the `Relationship` instance.
    public func relationship(to relationship: Relationship) -> RelationshipSourceModifier<Self> {
        RelationshipSourceModifier(self, relationship)
    }
}
