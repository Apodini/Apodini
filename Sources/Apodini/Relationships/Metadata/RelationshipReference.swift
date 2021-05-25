//
// Created by Andreas Bauer on 18.01.21.
//

extension TypedContentMetadataNamespace {
    /// Shorthand for using a pretyped `RelationshipReference`.
    public typealias References<To: Identifiable> = RelationshipReference<Self, To> where To.ID: LosslessStringConvertible
}

/// A `RelationshipReference` can be used to create a referencing relationship for the annotated `Content` type.
/// A relationship reference uses the value of properties holding the identifier of the target type
/// to resolve a relationship with the given values.
public class RelationshipReference<From, To: Identifiable>: RelationshipsContentMetadataBlock
    where To.ID: LosslessStringConvertible {
    public typealias Key = RelationshipSourceCandidateContextKey
    override public var value: [PartialRelationshipSourceCandidate] {
        [PartialRelationshipSourceCandidate(reference: name, destinationType: destinationType, resolvers: resolvers)]
    }

    let name: String
    let destinationType: To.Type
    let resolvers: [AnyPathParameterResolver]

    /// Creates a new `RelationshipReference`, referencing from the specified type using the specified resolver.
    /// - Parameters:
    ///
    /// A example definition for a Metadata definition looks like the following:
    /// ```swift
    /// static var metadata: Metadata {
    ///   References<SomeType>(as: "someName", identifiedBy: \.someId)
    /// }
    /// ```
    ///
    ///   - type: The reference type.
    ///   - name: The name of the reference.
    ///   - keyPath: A resolver for the path parameter of the destination.
    public convenience init(to type: To.Type = To.self, as name: String, identifiedBy keyPath: KeyPath<From, To.ID>) {
        self.init(to: type, as: name) {
            RelationshipIdentification(type, identifiedBy: keyPath)
        }
    }

    /// Creates a new `RelationshipReference`, referencing from the specified type using the specified resolver.
    ///
    /// A example definition for a Metadata definition looks like the following:
    /// ```swift
    /// static var metadata: Metadata {
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
    public convenience init(to type: To.Type = To.self, as name: String, identifiedBy keyPath: KeyPath<From, To.ID?>) {
        self.init(to: type, as: name) {
            RelationshipIdentification(type, identifiedBy: keyPath)
        }
    }

    /// Creates a new `RelationshipReference`, referencing from the specified type using the specified resolvers.
    ///
    /// A example definition for a Metadata definition looks like the following:
    /// ```swift
    /// static var metadata: Metadata {
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
