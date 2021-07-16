//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@resultBuilder
public enum RelationshipIdentificationBuilder<From> {
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
