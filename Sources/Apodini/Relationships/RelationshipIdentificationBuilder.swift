//
// Created by Andreas Bauer on 21.01.21.
//

// swiftlint:disable missing_docs

#if swift(>=5.4)
@resultBuilder
public enum RelationshipIdentificationBuilder<From> {}
#else
@_functionBuilder
public enum RelationshipIdentificationBuilder<From> {}
#endif

public extension RelationshipIdentificationBuilder {
    static func buildExpression<To: Identifiable>(_ expression: RelationshipIdentification<From, To>) -> [AnyRelationshipIdentification] {
        [AnyRelationshipIdentification(from: expression)]
    }

    // swiftlint:disable:next discouraged_optional_collection
    static func buildOptional(_ component: [AnyRelationshipIdentification]?) -> [AnyRelationshipIdentification] {
        component ?? []
    }

    static func buildEither(first: [AnyRelationshipIdentification]) -> [AnyRelationshipIdentification] {
        first
    }

    static func buildEither(second: [AnyRelationshipIdentification]) -> [AnyRelationshipIdentification] {
        second
    }

    static func buildBlock(_ components: [AnyRelationshipIdentification]...) -> [AnyRelationshipIdentification] {
        Array(components.joined())
    }
}
