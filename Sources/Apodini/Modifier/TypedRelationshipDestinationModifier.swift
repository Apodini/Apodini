//
// Created by Andreas Bauer on 20.01.21.
//

public struct TypedRelationshipDestinationModifier<H: Handler, To>: HandlerModifier {
    public let component: H

    let name: String
    let destinationType: To.Type

    init(_ component: H, _ name: String, _ destinationType: To.Type) {
        self.component = component
        self.name = name
        self.destinationType = destinationType

        precondition(name != "self", "The relationship name 'self' is reserved. To model relationship inheritance please use `Inherits`!")
    }
}

extension TypedRelationshipDestinationModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        let candidate = PartialRelationshipSourceCandidate(link: name, destinationType: destinationType)
        visitor.addContext(RelationshipSourceCandidateContextKey.self, value: [candidate], scope: .current)
        component.accept(visitor)
    }
}

extension Handler {
    /// A `relationship(name:of:)` modifier can be used to indicate that this `Handler`
    /// has a relationship with the specified name to a `Handler` which returns the specified type.
    ///
    /// - Parameters:
    ///   - name: The name of the relationship.
    ///   - type: The return type of the `Handler` the relationship points to.
    /// - Returns: The modified `Handler` with the added Relationship.
    public func relationship<To>(name: String, to type: To.Type) -> TypedRelationshipDestinationModifier<Self, To> {
        TypedRelationshipDestinationModifier(self, name, type)
    }
}
