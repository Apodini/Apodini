//
// Created by Andreas Bauer on 18.01.21.
//

extension TypedContentMetadataNamespace {
    /// Shorthand for using a pretyped `RelationshipInheritance`.
    public typealias Inherits<To> = RelationshipInheritance<Self, To>
}

/// A `RelationshipInheritance` can be used to indicate that the annotated `Content` type
/// inherits Relationships from the specified target type.
public class RelationshipInheritance<From, To>: RelationshipsContentMetadataBlock {
    public typealias Key = RelationshipSourceCandidateContextKey
    override public var value: [PartialRelationshipSourceCandidate] {
        [PartialRelationshipSourceCandidate(destinationType: destinationType, resolvers: resolvers)]
    }

    let destinationType: To.Type
    let resolvers: [AnyPathParameterResolver]

    private init(from type: To.Type = To.self, resolvers: [AnyPathParameterResolver]) {
        self.destinationType = type
        self.resolvers = resolvers
        precondition(From.self != To.self, "Can't define circular relationship inheritance. 'self' points to itself!")
    }

    /// Creates a new `RelationshipInheritance`, inheriting from the specified type.
    ///
    /// A example definition for a Metadata definition looks like the following:
    /// ```swift
    /// static var metadata: Metadata {
    ///   Inherits<SomeType>()
    /// }
    /// ```
    ///
    /// - Parameter type: The type to inherit from.
    public convenience init(from type: To.Type = To.self) {
        self.init(from: type, resolvers: [])
    }

    /// Creates a new `RelationshipInheritance`, inheriting from the specified type using the specified resolver.
    /// Additionally it adds specified resolvers for a path parameter in the path of the destination.
    ///
    /// A example definition for a Metadata definition looks like the following:
    /// ```swift
    /// static var metadata: Metadata {
    ///   Inherits<SomeType> {
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
    ///   - type: The type to inherit from.
    ///   - identifications: A list of resolvers for path parameter of the destination.
    public convenience init(
        from type: To.Type = To.self,
        @RelationshipIdentificationBuilder<From> identifiedBy identifications: () -> [AnyRelationshipIdentification]
    ) {
        self.init(from: type, resolvers: identifications().map { $0.resolver })
    }
}

extension RelationshipInheritance where To: Identifiable, To.ID: LosslessStringConvertible {
    /// Creates a new `RelationshipInheritance`, inheriting from the specified type using the specified resolver.
    /// Additionally it adds a specified resolver for a path parameter in the path of the destination.
    ///
    /// A example definition for a Metadata definition looks like the following:
    /// ```swift
    /// static var metadata: Metadata {
    ///   Inherits<SomeType>(identifiedBy: \.someId)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - type: The type to inherit from.
    ///   - keyPath: A resolver for a path parameter of the destination.
    public convenience init(from type: To.Type = To.self, identifiedBy keyPath: KeyPath<From, To.ID>) {
        self.init(from: type) {
            RelationshipIdentification(type, identifiedBy: keyPath)
        }
    }
}

extension RelationshipInheritance where From: Identifiable, To: Identifiable, From.ID == To.ID, To.ID: LosslessStringConvertible {
    /// Creates a new `RelationshipInheritance`, inheriting from the specified type using the specified resolver.
    /// As the source type inherits from `Identifiable` the `Identifiable.id` property is automatically added as a resolver.
    ///
    /// A example definition for a Metadata definition looks like the following:
    /// ```swift
    /// static var metadata: Metadata {
    ///   // if the self type conforms to `Identifiable` \.id will be automatically added
    ///   // as a resolver for the Self type, if this shortcut init is chosen.
    ///   Inherits<SomeType>()
    /// }
    /// ```
    ///
    /// - Parameter type: The type to inherit from.
    public convenience init(from type: To.Type = To.self) {
        self.init(from: type, identifiedBy: \From.id)
    }
}
