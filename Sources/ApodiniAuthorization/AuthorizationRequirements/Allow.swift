//
// Created by Andreas Bauer on 09.07.21.
//

/// ``Allow`` represents a ``ConditionalAuthorizationRequirement`` which results in a
/// ``RequirementResult/fulfilled`` if the corresponding ``AuthorizationCondition`` predicate evaluates to `true`.
public struct Allow<Element: Authenticatable>: ConditionalAuthorizationRequirement {
    public var condition: AuthorizationCondition<Element>

    public init(if fullFills: AuthorizationCondition<Element>) {
        self.condition = fullFills
    }

    public func evaluate(for element: Element) throws -> RequirementResult {
        try condition.predicate(element)
            ? .fulfilled(cause: .result(self))
            : .undecided(cause: .result(self))
    }
}
