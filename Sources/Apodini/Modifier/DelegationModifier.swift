//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import ApodiniUtils
import OrderedCollections

// MARK: Component+DelegationModifier

extension Component {
    /// Use a `DelegatingHandlerInitializer` to create a fitting delegating `Handler` for each of the `Component`'s endpoints.
    /// All instances created by the `initializer` can delegate evaluations to their respective child-`Handler` using `Delegate`.
    /// - Parameters:
    ///   - ensureInitializerTypeUniqueness: If set to true, it is ensured that the same ``DelegatingHandlerInitializer``
    ///     is only used a single time, even when inserted multiple times.
    ///   - inverseOrder: Set this to true if the according DelegatingHandler should act on the output of
    ///     the delegated Handler. Those Handler typically call the delegate first and then execute their own logic.
    ///     Therefore, such an initializer which is added first, should be inserted on the "innerst" position not
    ///     the "outerst", as it should be the first to act once handle returns.
    public func delegated<I: DelegatingHandlerInitializer>(
        by initializer: I,
        ensureInitializerTypeUniqueness: Bool = false,
        inverseOrder: Bool = false
    ) -> DelegationModifier<Self, I> {
        DelegationModifier(
            self,
            initializer: initializer,
            ensureInitializerTypeUniqueness: ensureInitializerTypeUniqueness,
            inverseOrder: inverseOrder
        )
    }
}

// MARK: DelegationModifier

public struct DelegationModifier<C: Component, I: DelegatingHandlerInitializer>: Modifier {
    public typealias ModifiedComponent = C
    
    public let component: C
    private let entry: DelegatingHandlerContextKey.Entry

    fileprivate init(_ component: C, initializer: I, ensureInitializerTypeUniqueness: Bool = false, inverseOrder: Bool = false) {
        self.component = component
        self.entry = .init(initializer, ensureInitializerTypeUniqueness: ensureInitializerTypeUniqueness, inverseOrder: inverseOrder)
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(
            DelegatingHandlerContextKey.self,
            value: [entry],
            scope: .environment
        )
    }
}

extension DelegationModifier: HandlerModifier where Self.ModifiedComponent: Handler {
    public typealias Response = I.Response
}


// MARK: DelegatingHandlerInitializer

/// A `DelegatingHandlerInitializer` is used to dynamically stack **delegating** `Handler`s on
/// `Component`s. The `DelegatingHandlerInitializer`'s `instance` method is called once for
/// every related endpoint.
public protocol DelegatingHandlerInitializer: AnyDelegatingHandlerInitializer {
    /// The `Response` type of the **delegating** `Handler`s that is returned by `instance`. This
    /// type is only relevant for the compile-time type-system and can be used to allow usage of
    /// `HandlerModifier`s that are restricted to a certain context which depends on `Response`.
    /// - Note: On a non-`Handler` context, this type can be set to `Never`.
    associatedtype Response: ResponseTransformable
    
    /// Build a partially type-erased `Handler`-instance that delegates to the given `delegate`.
    func instance<D: Handler>(for delegate: D) throws -> SomeHandler<Response>
}

/// A base-protocol for the internal functionality of `DelegatingHandlerInitializer`s.
/// - Note: Do not implement manually. Use `DelegatingHandlerInitializer` instead.
public protocol AnyDelegatingHandlerInitializer {
    /// A type-erased version of `DelegatingHandlerInitializer`'s `instance`.
    func anyinstance<D: Handler>(for delegate: D) throws -> AnyHandler
    
    /// A visitor-function that calls the given `filter` and returns its result by default.
    func evaluate(filter: DelegationFilter) -> Bool
}

public extension AnyDelegatingHandlerInitializer {
    /// The default implementation for `evaluate`, which calls the filter under any condition.
    func evaluate(filter: DelegationFilter) -> Bool {
        filter(self)
    }
}

extension AnyDelegatingHandlerInitializer {
    var id: ObjectIdentifier {
        if let filter = self as? AnyDelegateFilter {
            return ObjectIdentifier(type(of: filter.filter))
        }
        return ObjectIdentifier(Self.self)
    }
}

public extension DelegatingHandlerInitializer {
    /// The default implementation for `anyinstance`, which erases the type of the `SomeHandler` returned
    /// by `.instance(for:)`.
    func anyinstance<D>(for delegate: D) throws -> AnyHandler where D: Handler {
        try instance(for: delegate).anyHandler
    }
}

// MARK: DelegatingHandlerContextKey

/// Key to store Delegating Handler Initializer
public struct DelegatingHandlerContextKey: ContextKey {
    public typealias Value = OrderedSet<Entry>
    public static var defaultValue: Value = []

    public static func reduce(value: inout Value, nextValue: Value) {
        value.append(contentsOf: nextValue)
    }
}

extension DelegatingHandlerContextKey {
    /// Represents the entry type for the value of an ``DelegatingHandlerContextKey``
    public class Entry {
        /// Every entry of the ``DelegatingHandlerContextKey`` is identified by a instance specific
        /// `UUID` used to check if we already inserted into the ``Handler`` stack when parsing initializers.
        let uuid: UUID

        /// The according ``AnyDelegatingHandlerInitializer`` used to instantiate the delegating ``Handler``.
        let initializer: AnyDelegatingHandlerInitializer

        /// If set to true, it is ensure that the same ``AnyDelegatingHandlerInitializer``, even though
        /// when inserted multiple times into the context, is only used a single time (the first time it got inserted).
        let ensureInitializerTypeUniqueness: Bool

        let inverseOrder: Bool

        var markedFiltered = false

        /// Creates a new ``DelegatingHandlerContextKey/Entry`` instance.
        /// - Parameters:
        ///   - initializer: The ``AnyDelegatingHandlerInitializer`` for the delegating Handler.
        ///   - ensureInitializerTypeUniqueness: If set to true, it is ensured that the same ``DelegatingHandlerInitializer``
        ///     is only used a single time, even when inserted multiple times.
        ///   - inverseOrder: Set this to true if the according DelegatingHandler should act on the output of
        ///     the delegated Handler. Those Handler typically call the delegate first and then execute their own logic.
        ///     Therefore, such an initializer which is added first, should be inserted on the "innermost" position not
        ///     the "outermost", as it should be the first to act once handle returns.
        public init(
            _ initializer: AnyDelegatingHandlerInitializer,
            ensureInitializerTypeUniqueness: Bool = false,
            inverseOrder: Bool = false
        ) {
            self.uuid = UUID()
            self.initializer = initializer
            self.ensureInitializerTypeUniqueness = ensureInitializerTypeUniqueness
            self.inverseOrder = inverseOrder
        }
    }
}

extension DelegatingHandlerContextKey.Entry: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    public static func == (lhs: DelegatingHandlerContextKey.Entry, rhs: DelegatingHandlerContextKey.Entry) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

extension DelegatingHandlerContextKey.Entry: CustomStringConvertible {
    public var description: String {
        """
        Apodini.DelegatingHandlerContextKey.Entry(\
        uuid: \(uuid), \
        initializer: \(initializer), \
        ensureInitializerTypeUniqueness: \(ensureInitializerTypeUniqueness), \
        inverseOrder: \(inverseOrder), \
        markedFiltered: \(markedFiltered)\
        )
        """
    }
}
