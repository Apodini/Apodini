//
// Created by Andreas Bauer on 18.01.21.
//

/// A `RelationshipReference` can be used to create a referencing relationship for the annotated `Content` type.
/// A relationship reference uses the value of properties holding the identifier of the target type
/// too resolve a relationship with the given values.
public struct RelationshipReference<From, To: Identifiable>: RelationshipDefinition where To.ID: LosslessStringConvertible {
    let name: String
    let destinationType: To.Type
    let resolvers: [AnyPathParameterResolver]

    /// Creates a new `RelationshipReference`, referencing from the specified type using the specified resolver.
    /// - Parameters:
    ///   - type: The reference type.
    ///   - name: The name of the reference.
    ///   - keyPath: A resolver for the path parameter of the destination.
    public init(to type: To.Type = To.self, as name: String, at keyPath: KeyPath<From, To.ID>) {
        self.init(to: type, as: name) {
            RelationshipIdentification(type, at: keyPath)
        }
    }

    /// Creates a new `RelationshipReference`, referencing from the specified type using the specified resolver.
    /// - Parameters:
    ///   - type: The reference type.
    ///   - name: The name of the reference.
    ///   - keyPath: A resolver for the path parameter of the destination.
    public init(to type: To.Type = To.self, as name: String, at keyPath: KeyPath<From, To.ID?>) {
        self.init(to: type, as: name) {
            RelationshipIdentification(type, at: keyPath)
        }
    }

    /// Creates a new `RelationshipReference`, referencing from the specified type using the specified resolvers.
    /// - Parameters:
    ///   - type: The reference type.
    ///   - name: The name of the reference.
    ///   - identifications: Resolvers to all path parameters of the destination.
    public init(
        to type: To.Type = To.self,
        as name: String,
        @RelationshipIdentificationBuilder<From> at identifications: () -> [AnyRelationshipIdentification]
    ) {
        self.name = name
        self.destinationType = type
        self.resolvers = identifications().map { $0.resolver }

        precondition(name != "self", "The relationship name 'self' is reserved. To model relationship inheritance please use `Inherits`!")
        precondition(From.self != To.self, "Can't define circular relationship references. '\(name)' points to itself!")
    }
}

extension RelationshipReference: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        let candidate = PartialRelationshipSourceCandidate(reference: name, destinationType: destinationType, resolvers: resolvers)
        visitor.addContext(RelationshipSourceCandidateContextKey.self, value: [candidate], scope: .current)
    }
}
