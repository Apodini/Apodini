//
// Created by Andreas Bauer on 18.01.21.
//

/// A `RelationshipSource` can be used to indicate that the annotated `Content` type
/// has a relationship with the specified name to a `Handler` which returns the specified type.
/// This is the DSL equivalent of the modifier `Handler.relationship(name:to:).
/// In addition to the modifier, the `RelationshipSource` allows to define `RelationshipIdentification`s
/// to add resolvers for path parameters of the destination.
public struct RelationshipSource<From, To>: RelationshipDefinition {
    let name: String
    let destinationType: To.Type
    let resolvers: [AnyPathParameterResolver]

    /// Creates a new `RelationshipSource` with the specified name targeting a `Handler` which returns the specified type.
    /// - Parameters:
    ///   - name: The name of the relationship.
    ///   - type: The return type of the relationship destination.
    public init(name: String, to type: To.Type = To.self) {
        self.name = name
        self.destinationType = type
        self.resolvers = []

        precondition(name != "self", "The relationship name 'self' is reserved. To model relationship inheritance please use `Inherits`!")
    }
}

extension RelationshipSource where To: Identifiable, To.ID: LosslessStringConvertible {
    /// Creates a new `RelationshipSource` with the specified name targeting a `Handler` which returns the specified type.
    /// Additionally it adds a specified resolver for a path parameter in the path of the destination.
    /// - Parameters:
    ///   - name: The name of the relationship.
    ///   - type: The return type of the relationship destination.
    ///   - keyPath: A resolver for a path parameter of the destination.
    public init(name: String, to type: To.Type = To.self, parameter keyPath: KeyPath<From, To.ID>) {
        self.init(name: name, to: type) {
            RelationshipIdentification(type, identifiedBy: keyPath)
        }
    }

    /// Creates a new `RelationshipSource` with the specified name targeting a `Handler` which returns the specified type.
    /// Additionally it adds specified resolvers for a path parameter in the path of the destination.
    /// - Parameters:
    ///   - name: The name of the relationship.
    ///   - type: The return type of the relationship destination.
    ///   - identifications: A list of resolvers for path parameter of the destination.
    public init(
        name: String,
        to type: To.Type = To.self,
        @RelationshipIdentificationBuilder<From> parameters identifications: () -> [AnyRelationshipIdentification]
    ) {
        self.name = name
        self.destinationType = type
        self.resolvers = identifications().map { $0.resolver }

        precondition(name != "self", "The relationship name 'self' is reserved. To model relationship inheritance please use `Inherits`!")
    }
}

extension RelationshipSource: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        let candidate = PartialRelationshipSourceCandidate(link: name, destinationType: destinationType, resolvers: resolvers)
        visitor.addContext(RelationshipSourceCandidateContextKey.self, value: [candidate], scope: .current)
    }
}
