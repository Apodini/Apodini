//
// Created by Andreas Bauer on 07.07.21.
//

// swiftlint:disable static_operator

/// An ``AuthorizationCondition`` represents some sort of predicate which is evaluated against an ``Authenticatable`` instance.
///
/// An ``AuthorizationCondition`` is constructed using `KeyPath` expressions of the respective ``Authenticatable`` type.
/// All common binary and unary operators are supported.
///
/// ## Equality Operators
/// Equality Operators (`==`, `!=`) are available for KeyPaths of a ``Authenticatable`` type pointing to an `Equatable` property.
///
/// ```swift
/// let condition: AuthorizationCondition<Example>
///
/// condition = \.someString == <expression>
///
/// condition = \.someString != <expression>
/// ```
///
/// ## Comparison Operators
/// Comparison Operators (`>`, `>=`, `<`, `<=`) are available for KeyPaths of a ``Authenticatable`` type pointing to a `Comparable` property.
///
/// ```swift
/// let condition: AuthorizationCondition<Example>
///
/// condition = \.someInt > <expression>
///
/// condition = \.someInt >= <expression>
///
/// condition = \.someInt < <expression>
///
/// condition = \.someInt <= <expression>
/// ```
///
/// ## Logical Operators
/// The typical `&&`, `||` and `!` logical operators can be used on ``AuthorizationCondition`` instances.
/// Those can be arbitrarily nested.
///
/// ```swift
/// condition1 && condition2
///
/// condition1 || condition2
///
/// !condition1
/// ```
public struct AuthorizationCondition<A: Authenticatable> {
    let predicate: (A) throws -> Bool

    init(_ predicate: @escaping (A) throws -> Bool) {
        self.predicate = predicate
    }
}

extension AuthorizationCondition: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.init { _ in value }
    }
}

// MARK: Authorization Logical Operators

/// The `&&` logical operator can be used on two ``AuthorizationCondition`` instances combining their
/// results with a logical AND.
public func && <A> (lhs: AuthorizationCondition<A>, rhs: AuthorizationCondition<A>) -> AuthorizationCondition<A> {
    AuthorizationCondition { state in try lhs.predicate(state) && rhs.predicate(state) }
}

/// The `||` logical operator can be used on two ``AuthorizationCondition`` instances
/// performing a logical NOT on the result.
public func || <A> (lhs: AuthorizationCondition<A>, rhs: AuthorizationCondition<A>) -> AuthorizationCondition<A> {
    AuthorizationCondition { state in try lhs.predicate(state) || rhs.predicate(state) }
}

/// The `!` unary logical operator can be used on a ``AuthorizationCondition`` instance, combining their
/// results with a logical AND.
public prefix func ! <A> (rhs: AuthorizationCondition<A>) -> AuthorizationCondition<A> {
    AuthorizationCondition { state in try !rhs.predicate(state) }
}


// MARK: Authenticatable Comparison Operators

/// The `==` comparison operators can be use on a `KeyPath` of a ``Authenticatable`` on the lhs and a according expression on the rhs.
public func == <A: Authenticatable, P: Equatable> (lhs: KeyPath<A, P>, rhs: @autoclosure @escaping () -> P) -> AuthorizationCondition<A> {
    AuthorizationCondition { $0[keyPath: lhs] == rhs() }
}

/// The `!=` comparison operators can be use on a `KeyPath` of a ``Authenticatable`` on the lhs and a according expression on the rhs.
public func != <A: Authenticatable, P: Equatable> (lhs: KeyPath<A, P>, rhs: @autoclosure @escaping () -> P) -> AuthorizationCondition<A> {
    AuthorizationCondition { $0[keyPath: lhs] != rhs() }
}

/// The `<` comparison operators can be use on a `KeyPath` of a ``Authenticatable`` on the lhs and a according expression on the rhs.
public func < <A: Authenticatable, P: Comparable> (lhs: KeyPath<A, P>, rhs: @autoclosure @escaping () -> P) -> AuthorizationCondition<A> {
    AuthorizationCondition { $0[keyPath: lhs] < rhs() }
}

/// The `>` comparison operators can be use on a `KeyPath` of a ``Authenticatable`` on the lhs and a according expression on the rhs.
public func > <A: Authenticatable, P: Comparable> (lhs: KeyPath<A, P>, rhs: @autoclosure @escaping () -> P) -> AuthorizationCondition<A> {
    AuthorizationCondition { $0[keyPath: lhs] > rhs() }
}

/// The `<=` comparison operators can be use on a `KeyPath` of a ``Authenticatable`` on the lhs and a according expression on the rhs.
public func <= <A: Authenticatable, P: Comparable> (lhs: KeyPath<A, P>, rhs: @autoclosure @escaping () -> P) -> AuthorizationCondition<A> {
    AuthorizationCondition { $0[keyPath: lhs] <= rhs() }
}

/// The `>=` comparison operators can be use on a `KeyPath` of a ``Authenticatable`` on the lhs and a according expression on the rhs.
public func >= <A: Authenticatable, P: Comparable> (lhs: KeyPath<A, P>, rhs: @autoclosure @escaping () -> P) -> AuthorizationCondition<A> {
    AuthorizationCondition { $0[keyPath: lhs] >= rhs() }
}
