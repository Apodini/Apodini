//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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

public extension Verify {
    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the optional property
    /// pointed to by the `KeyPath` is not `nil`.
    ///
    /// ``init(isPresent:)`` is equivalent to ``init(ifPresent:)`` and only available in the ``Verify`` ``ConditionalAuthorizationRequirement``.
    /// - Parameter keyPath: The `KeyPath`.
    init<Value>(isPresent keyPath: KeyPath<Element, Value?>) {
        self.init(ifPresent: keyPath)
    }

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the optional property
    /// pointed to by the `KeyPath` is `nil`.
    ///
    /// ``init(isNil:):)`` is equivalent to ``init(ifNil:):)`` and only available in the ``Verify`` ``ConditionalAuthorizationRequirement``.
    /// - Parameter keyPath: The `KeyPath`.
    init<Value>(notPresent keyPath: KeyPath<Element, Value?>) {
        self.init(ifNil: keyPath)
    }

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the `Bool` property
    /// pointed to by the `KeyPath` holds the value `true`.
    ///
    /// ``init(that:)`` is equivalent to ``init(if:)`` and only available in the ``Verify`` ``ConditionalAuthorizationRequirement``.
    /// - Parameter boolKeyPath: The `KeyPath`.
    init(that boolKeyPath: KeyPath<Element, Bool>) {
        self.init(if: boolKeyPath)
    }

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the `Bool` property
    /// pointed to by the `KeyPath` holds the value `false`.
    ///
    /// ``init(not:)`` is equivalent to ``init(ifNot:)`` and only available in the ``Verify`` ``ConditionalAuthorizationRequirement``.
    /// - Parameter boolKeyPath: The `KeyPath`.
    init(not boolKeyPath: KeyPath<Element, Bool>) {
        self.init(ifNot: boolKeyPath)
    }
}
