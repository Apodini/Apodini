//
// Created by Andreas Bauer on 17.07.21.
//

/// ``Verify`` represents a ``ConditionalAuthorizationRequirement`` which results in a
/// ``RequirementResult/rejected`` if the corresponding ``AuthorizationCondition`` predicate evaluates to `false`
/// and otherwise continues execution of the remaining ``AuthorizationRequirement``.
public struct Verify<Element: Authenticatable>: ConditionalAuthorizationRequirement {
    public var condition: AuthorizationCondition<Element>

    public init(if fullFills: AuthorizationCondition<Element>) {
        self.condition = fullFills
    }

    public func evaluate(for element: Element) throws -> RequirementResult {
        try condition.predicate(element)
            ? .undecided(cause: .result(self))
            : .rejected(cause: .result(self))
    }
}
