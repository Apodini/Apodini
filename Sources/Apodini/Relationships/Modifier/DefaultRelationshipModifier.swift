//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
struct DefaultRelationshipContextKey: OptionalContextKey {
    // This OptionalContextKey doesn't carry any additional context.
    // We only need to check if the context key exists on a Endpoint
    typealias Value = Void
}

public struct DefaultRelationshipModifier<H: Handler>: HandlerModifier {
    public let component: H

    init(_ component: H) {
        self.component = component
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DefaultRelationshipContextKey.self, value: (), scope: .current)
    }
}

extension Handler {
    /// A `defaultRelationship` modifier can be used to mark the return type - the `Content` type -
    /// as "default" for Relationships inferred from type information.
    ///
    /// - Returns: The modified `Handler` with the `Content` being marked as default.
    public func defaultRelationship() -> DefaultRelationshipModifier<Self> {
        DefaultRelationshipModifier(self)
    }
}
