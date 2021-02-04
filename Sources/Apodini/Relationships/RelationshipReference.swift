//
// Created by Andreas Bauer on 18.01.21.
//

/// A `RelationshipReference` can be used to create a referencing relationship for the annotated `Content` type.
/// A relationship reference uses the value of properties holding the identifier of the target type
/// to resolve a relationship with the given values.
public struct RelationshipReference<From, To: Identifiable>: RelationshipDefinition where To.ID: LosslessStringConvertible {
    let name: String
    let destinationType: To.Type
    let resolvers: [AnyPathParameterResolver]

    /// Creates a new `RelationshipReference`, referencing from the specified type using the specified resolver.
    /// - Parameters:
    ///
    /// A example definition for a `WithRelationships` definition looks like the following:
    /// ```swift
    /// static var relationships: Relationships {
    ///   References<SomeType>(as: "someName", identifiedBy: \.someId)
    /// }
    /// ```
    ///
    ///   - type: The reference type.
    ///   - name: The name of the reference.
    ///   - keyPath: A resolver for the path parameter of the destination.
    public init(to type: To.Type = To.self, as name: String, identifiedBy keyPath: KeyPath<From, To.ID>) {
        self.init(to: type, as: name) {
            RelationshipIdentification(type, identifiedBy: keyPath)
        }
    }

    /// Creates a new `RelationshipReference`, referencing from the specified type using the specified resolver.
    ///
    /// A example definition for a `WithRelationships` definition looks like the following:
    /// ```swift
    /// static var relationships: Relationships {
    ///   // The \.someId property is of type Optional. The path parameter will only be resolved
    ///   // if the parameter value is present
    ///   References<SomeType>(as: "someName", identifiedBy: \.someId)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - type: The reference type.
    ///   - name: The name of the reference.
    ///   - keyPath: A resolver for the path parameter of the destination.
    public init(to type: To.Type = To.self, as name: String, identifiedBy keyPath: KeyPath<From, To.ID?>) {
        self.init(to: type, as: name) {
            RelationshipIdentification(type, identifiedBy: keyPath)
        }
    }

    /// Creates a new `RelationshipReference`, referencing from the specified type using the specified resolvers.
    ///
    /// A example definition for a `WithRelationships` definition looks like the following:
    /// ```swift
    /// static var relationships: Relationships {
    ///   References<SomeType>(as: "someName") {
    ///     // Every entry here relates to one `PathParameter` definition
    ///     // in the path of the destination. `Identifying` must be added
    ///     // for the identifying type of the `PathParameter`
    ///     Identifying<SomeOtherType>(identifiedBy: \.someId0)
    ///     Identifying<SomeType>(identifiedBy: \.someId1)
    ///   }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - type: The reference type.
    ///   - name: The name of the reference.
    ///   - identifications: Resolvers to all path parameters of the destination.
    public init(
        to type: To.Type = To.self,
        as name: String,
        @RelationshipIdentificationBuilder<From> identifiedBy identifications: () -> [AnyRelationshipIdentification]
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
