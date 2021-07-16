//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

public struct RelationshipDestinationContextKey: ContextKey {
    public typealias Value = [Relationship]
    public static var defaultValue: [Relationship] = []
}

public struct RelationshipDestinationModifier<H: Handler>: HandlerModifier {
    public let component: H
    let relationship: Relationship

    init(_ component: H, _ relationship: Relationship) {
        self.component = component
        self.relationship = relationship
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(RelationshipDestinationContextKey.self, value: [relationship], scope: .current)
    }
}

extension Handler {
    /// A `destination(of:)` modifier can be used to mark this `Handler`
    /// as the destination for the given `Relationship` instance.
    ///
    /// - Parameter relationship: The `Relationship` instance for which this `Handler` should be the destination for.
    /// - Returns: The modified `Handler` being marked as the destination for the `Relationship` instance.
    public func destination(of relationship: Relationship) -> RelationshipDestinationModifier<Self> {
        RelationshipDestinationModifier(self, relationship)
    }
}
