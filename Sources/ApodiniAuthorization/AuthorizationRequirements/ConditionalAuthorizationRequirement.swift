//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// A ``ConditionalAuthorizationRequirement`` represents a ``AuthorizationRequirement`` which uses
/// an ``AuthorizationCondition`` in its evaluation.
public protocol ConditionalAuthorizationRequirement: AuthorizationRequirement {
    /// The predicate wrapped in an ``AuthorizationCondition``.
    var condition: AuthorizationCondition<Element> { get }

    /// Creates a new instance using custom created ``AuthorizationCondition``.
    ///
    /// This is the only initializer which doesn't have a default implementation.
    /// - Parameter fullFills: The ``AuthorizationCondition``.
    init(if fullFills: AuthorizationCondition<Element>)


    /// Creates a new instance where the ``condition`` evaluates to `true`.
    init()

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the optional property
    /// pointed to by the `KeyPath` is not `nil`.
    /// - Parameter keyPath: The `KeyPath`.
    init<Value>(ifPresent keyPath: KeyPath<Element, Value?>)

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the optional property
    /// pointed to by the `KeyPath` is `nil`.
    /// - Parameter keyPath: The `KeyPath`.
    init<Value>(ifNil keyPath: KeyPath<Element, Value?>)

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the `Bool` property
    /// pointed to by the `KeyPath` holds the value `true`.
    /// - Parameter keyPath: The `KeyPath`.
    init(if boolKeyPath: KeyPath<Element, Bool>)

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the `Bool` property
    /// pointed to by the `KeyPath` holds the value `false`.
    /// - Parameter keyPath: The `KeyPath`.
    init(ifNot boolKeyPath: KeyPath<Element, Bool>)

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the `Collection` property
    /// pointed to by the `KeyPath` contains the respective `Element`.
    /// - Parameters:
    ///   - contains: The `Equatable` Element which should be contained in the collection.
    ///   - collection: The `KeyPath` pointing to a `Collection` of `Equatable`s.
    init<List: Collection>(contains: List.Element, in collection: KeyPath<Element, List>) where List.Element: Equatable

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the `Collection` property
    /// pointed to by the `KeyPath` does NOT contain the respective `Element`.
    /// - Parameters:
    ///   - contains: The `Equatable` Element which should NOT be contained in the collection.
    ///   - collection: The `KeyPath` pointing to a `Collection` of `Equatable`s.
    init<List: Collection>(notContains: List.Element, in collection: KeyPath<Element, List>) where List.Element: Equatable

    /// Creates an ``AuthorizationCondition`` which forwards the result of the custom defined predicated.
    ///
    /// Any `ApodiniError` thrown by this predicate is forwarded to the respective
    /// ``AuthenticationScheme/mapFailedAuthorization(failedWith:)`. Therefore it might contain ``AuthenticationScheme``
    /// specific options, providing guidance on how the error is mapped to the according wire format.
    /// - Parameter custom: The predicated which should be evaluated on the ``Authenticatable`` instance.
    init(custom: @escaping (Element) throws -> Bool)
}

public extension ConditionalAuthorizationRequirement {
    /// Creates a new instance where the ``condition`` evaluates to true.
    init() {
        self.init(if: AuthorizationCondition { _ in true })
    }

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the optional property
    /// pointed to by the `KeyPath` is not `nil`.
    /// - Parameter keyPath: The `KeyPath`.
    init<Value>(ifPresent keyPath: KeyPath<Element, Value?>) {
        self.init(if: AuthorizationCondition { instance in instance[keyPath: keyPath] != nil })
    }

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the optional property
    /// pointed to by the `KeyPath` is `nil`.
    /// - Parameter keyPath: The `KeyPath`.
    init<Value>(ifNil keyPath: KeyPath<Element, Value?>) {
        self.init(if: AuthorizationCondition { instance in instance[keyPath: keyPath] == nil })
    }

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the `Bool` property
    /// pointed to by the `KeyPath` holds the value `true`.
    /// - Parameter boolKeyPath: The `KeyPath`.
    init(if boolKeyPath: KeyPath<Element, Bool>) {
        self.init(if: AuthorizationCondition { instance in instance[keyPath: boolKeyPath] })
    }

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the `Bool` property
    /// pointed to by the `KeyPath` holds the value `false`.
    /// - Parameter boolKeyPath: The `KeyPath`.
    init(ifNot boolKeyPath: KeyPath<Element, Bool>) {
        self.init(if: AuthorizationCondition { instance in !instance[keyPath: boolKeyPath] })
    }

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the `Collection` property
    /// pointed to by the `KeyPath` contains the respective `Element`.
    /// - Parameters:
    ///   - contains: The `Equatable` Element which should be contained in the collection.
    ///   - collection: The `KeyPath` pointing to a `Collection` of `Equatable`s.
    init<List: Collection>(contains: List.Element, in collection: KeyPath<Element, List>) where List.Element: Equatable {
        self.init(if: AuthorizationCondition { instance in instance[keyPath: collection].contains(contains) })
    }

    /// Creates an ``AuthorizationCondition`` which evaluates to `true` if the `Collection` property
    /// pointed to by the `KeyPath` does NOT contain the respective `Element`.
    /// - Parameters:
    ///   - contains: The `Equatable` Element which should NOT be contained in the collection.
    ///   - collection: The `KeyPath` pointing to a `Collection` of `Equatable`s.
    init<List: Collection>(notContains: List.Element, in collection: KeyPath<Element, List>) where List.Element: Equatable {
        self.init(if: AuthorizationCondition { instance in !instance[keyPath: collection].contains(notContains) })
    }

    /// Creates an ``AuthorizationCondition`` which forwards the result of the custom defined predicated.
    ///
    /// Any `ApodiniError` thrown by this predicate is forwarded to the respective
    /// ``AuthenticationScheme/mapFailedAuthorization(failedWith:)`. Therefore it might contain ``AuthenticationScheme``
    /// specific options, providing guidance on how the error is mapped to the according wire format.
    /// - Parameter custom: The predicated which should be evaluated on the ``Authenticatable`` instance.
    init(custom predicate: @escaping (Element) throws -> Bool) {
        self.init(if: AuthorizationCondition(predicate))
    }
}
