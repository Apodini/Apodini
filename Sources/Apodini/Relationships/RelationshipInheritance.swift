//
// Created by Andreas Bauer on 18.01.21.
//

/// A `RelationshipInheritance` can be used to indicate that the annotated `Content` type
/// inherits Relationships from the specified target type.
public struct RelationshipInheritance<From, To>: RelationshipDefinition {
    let destinationType: To.Type
    let resolvers: [AnyPathParameterResolver]

    private init(from type: To.Type = To.self, resolvers: [AnyPathParameterResolver]) {
        self.destinationType = type
        self.resolvers = resolvers
        precondition(From.self != To.self, "Can't define circular relationship inheritance. 'self' points to itself!")
    }

    /// Creates a new `RelationshipInheritance`, inheriting from the specified type.
    /// - Parameter type: The type to inherit from.
    public init(from type: To.Type = To.self) {
        self.init(from: type, resolvers: [])
    }

    /// Creates a new `RelationshipInheritance`, inheriting from the specified type using the specified resolver.
    /// Additionally it adds specified resolvers for a path parameter in the path of the destination.
    /// - Parameters:
    ///   - type: The type to inherit from.
    ///   - identifications: A list of resolvers for path parameter of the destination.
    public init(
        from type: To.Type = To.self,
        @RelationshipIdentificationBuilder<From> at identifications: () -> [AnyRelationshipIdentification]
    ) {
        self.init(from: type, resolvers: identifications().map { $0.resolver })
    }
}

extension RelationshipInheritance where To: Identifiable, To.ID: LosslessStringConvertible {
    /// Creates a new `RelationshipInheritance`, inheriting from the specified type using the specified resolver.
    /// Additionally it adds a specified resolver for a path parameter in the path of the destination.
    /// - Parameters:
    ///   - type: The type to inherit from.
    ///   - keyPath: A resolver for a path parameter of the destination.
    public init(from type: To.Type = To.self, at keyPath: KeyPath<From, To.ID>) {
        self.init(from: type) {
            RelationshipIdentification(type, at: keyPath)
        }
    }
}

extension RelationshipInheritance where From: Identifiable, To: Identifiable, From.ID == To.ID, To.ID: LosslessStringConvertible {
    /// Creates a new `RelationshipInheritance`, inheriting from the specified type using the specified resolver.
    /// As the source type inherits from `Identifiable` the `Identifiable.id` property is automatically added as a resolver.
    /// - Parameter type: The type to inherit from.
    public init(from type: To.Type = To.self) {
        self.init(from: type, at: \From.id)
    }
}

extension RelationshipInheritance: SyntaxTreeVisitable {
    func accept(_ visitor: SyntaxTreeVisitor) {
        let candidate = PartialRelationshipSourceCandidate(destinationType: destinationType, resolvers: resolvers)
        visitor.addContext(RelationshipSourceCandidateContextKey.self, value: [candidate], scope: .current)
    }
}
