//
// Created by Andreas Bauer on 18.01.21.
//

extension TypedContentMetadataNamespace {
    /// Shorthand for using a pretyped `RelationshipSource`.
    public typealias Relationship<To> = RelationshipSource<Self, To>
}

/// A `RelationshipSource` can be used to indicate that the annotated `Content` type
/// has a relationship with the specified name to a `Handler` which returns the specified type.
/// This is the DSL equivalent of the modifier `Handler.relationship(name:to:).
/// In addition to the modifier, the `RelationshipSource` allows to define `RelationshipIdentification`s
/// to add resolvers for path parameters of the destination.
public class RelationshipSource<From, To>: RelationshipsContentMetadataBlock {
    public typealias Key = RelationshipSourceCandidateContextKey
    override public var value: [PartialRelationshipSourceCandidate] {
        [PartialRelationshipSourceCandidate(link: name, destinationType: destinationType, resolvers: resolvers)]
    }

    let name: String
    let destinationType: To.Type
    let resolvers: [AnyPathParameterResolver]

    fileprivate init(name: String, destinationType: To.Type, resolvers: [AnyPathParameterResolver]) {
        self.name = name
        self.destinationType = destinationType
        self.resolvers = resolvers

        precondition(name != "self", "The relationship name 'self' is reserved. To model relationship inheritance please use `Inherits`!")
    }

    /// Creates a new `RelationshipSource` with the specified name targeting a `Handler` which returns the specified type.
    ///
    /// A example definition for a Metadata definition looks like the following:
    /// ```swift
    /// static var metadata: Metadata {
    ///   Relationship<SomeType>(name: "someName")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the relationship.
    ///   - type: The return type of the relationship destination.
    public convenience init(name: String, to type: To.Type = To.self) {
        self.init(name: name, destinationType: type, resolvers: [])
    }
}

extension RelationshipSource where To: Identifiable, To.ID: LosslessStringConvertible {
    /// Creates a new `RelationshipSource` with the specified name targeting a `Handler` which returns the specified type.
    /// Additionally it adds a specified resolver for a path parameter in the path of the destination.
    ///
    /// A example definition for a Metadata definition looks like the following:
    /// ```swift
    /// static var Metadata: Metadata {
    ///   Relationship<SomeType>(name: "someName", parameter: \.someProperty)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the relationship.
    ///   - type: The return type of the relationship destination.
    ///   - keyPath: A resolver for a path parameter of the destination.
    public convenience init(name: String, to type: To.Type = To.self, parameter keyPath: KeyPath<From, To.ID>) {
        self.init(name: name, to: type) {
            RelationshipIdentification(type, identifiedBy: keyPath)
        }
    }

    /// Creates a new `RelationshipSource` with the specified name targeting a `Handler` which returns the specified type.
    /// Additionally it adds specified resolvers for a path parameter in the path of the destination.
    ///
    /// A example definition for a Metadata definition looks like the following:
    /// ```swift
    /// static var metadata: Metadata {
    ///   Relationship<SomeType>(name: "someName") {
    ///     // Every entry here relates to one `PathParameter` definition
    ///     // in the path of the destination. Those `Identifying definitions will be
    ///     // used to resolve any `PathParameter` annotated with the same identifying type.
    ///     Identifying<SomeOtherType>(identifiedBy: \.someId0)
    ///     Identifying<SomeType>(identifiedBy: \.someId1)
    ///   }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the relationship.
    ///   - type: The return type of the relationship destination.
    ///   - identifications: A list of resolvers for path parameter of the destination.
    public convenience init(
        name: String,
        to type: To.Type = To.self,
        @RelationshipIdentificationBuilder<From> parameters identifications: () -> [AnyRelationshipIdentification]
    ) {
        self.init(name: name, destinationType: type, resolvers: identifications().map { $0.resolver })
    }
}
