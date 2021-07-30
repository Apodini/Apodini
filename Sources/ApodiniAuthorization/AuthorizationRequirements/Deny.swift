//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// ``Deny`` represents a ``ConditionalAuthorizationRequirement`` which results in a
/// ``RequirementResult/rejected`` if the corresponding ``AuthorizationCondition`` predicate evaluates to `true`.
public struct Deny<Element: Authenticatable>: ConditionalAuthorizationRequirement {
    public var condition: AuthorizationCondition<Element>

    public init(if fullFills: AuthorizationCondition<Element>) {
        self.condition = fullFills
    }

    public func evaluate(for element: Element) throws -> RequirementResult {
        try condition.predicate(element)
            ? .rejected(cause: .result(self))
            : .undecided(cause: .result(self))
    }
}
