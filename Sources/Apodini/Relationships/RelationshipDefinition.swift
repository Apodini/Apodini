//
// Created by Andreas Bauer on 20.12.20.
//

/// The `WithRelationships` protocol can be used on `Content` definitions
/// on the return type of a `Handler` (the `Content` returned by last `ResponseTransformer` or
/// the `Handler` if there aren't any transformers).
/// The `relationships` property can be used to define `RelationshipDefinition`s for
/// the `Content` type annotated with this protocol.
public protocol WithRelationships {
    /// Defines a array of `RelationshipDefinition`s
    typealias Relationships = [RelationshipDefinition]

    /// Shorthand for using a pretyped `RelationshipReference`.
    typealias References<To: Identifiable> = RelationshipReference<Self, To> where To.ID: LosslessStringConvertible
    /// Shorthand for using a pretyped `RelationshipInheritance`.
    typealias Inherits<To> = RelationshipInheritance<Self, To>

    /// Shorthand for using a pretyped `RelationshipSource`.
    typealias Relationship<To> = RelationshipSource<Self, To>

    /// Shorthand for using a pretyped `RelationshipIdentification`.
    typealias Identifying<To: Identifiable> = RelationshipIdentification<Self, To> where To.ID: LosslessStringConvertible

    /// Defines `RelationshipDefinition`s for the given `Content` type.
    @RelationshipDefinitionBuilder
    static var relationships: Relationships { get }
}

/// A `RelationshipDefinition` defines any sort of relationship information for the
/// given `Content` type annotated with `WithRelationships`.
public protocol RelationshipDefinition {}

extension RelationshipDefinition {
    func accept(_ visit: SyntaxTreeVisitor) {
        if let visitable = self as? SyntaxTreeVisitable {
            visitable.accept(visit)
        } else {
            fatalError("\(self) conforms to \(RelationshipDefinition.self) but doesn't conform to \(SyntaxTreeVisitable.self)!")
        }
    }
}


struct RelationshipSourceCandidateContextKey: ContextKey {
    typealias Value = [PartialRelationshipSourceCandidate]
    static let defaultValue: Value = []

    static func reduce(value: inout [PartialRelationshipSourceCandidate], nextValue: () -> [PartialRelationshipSourceCandidate]) {
        value.append(contentsOf: nextValue())
    }
}


/// A function builder used to aggregate `RelationshipDefinition`.
@_functionBuilder
public enum RelationshipDefinitionBuilder {
    /// A method that transforms multiple `RelationshipDefinition`s
    public static func buildBlock(_ definitions: RelationshipDefinition...) -> [RelationshipDefinition] {
        definitions
    }
}
