//
//  DelegatingHandlerInitializer.swift
//  
//
//  Created by Max Obermeier on 06.06.21.
//

import Foundation
import ApodiniUtils
import OrderedCollections

// MARK: Component+DelegationModifier

extension Component {
    /// Use a `DelegatingHandlerInitializer` to create a fitting delegating `Handler` for each of the `Component`'s endpoints.
    /// All instances created by the `initializer` can delegate evaluations to their respective child-`Handler` using `Delegate`.
    /// - Parameter ensureInitializerTypeUniqueness: If set to true, it is ensure that the same ``DelegatingHandlerInitializer``,
    ///     even though when inserted multiple times into the context, is only used a single time (the first time it got added).
    public func delegated<I: DelegatingHandlerInitializer>(by initializer: I, ensureInitializerTypeUniqueness: Bool = false)
            -> DelegationModifier<Self, I> {
        DelegationModifier(self, initializer: initializer, ensureInitializerTypeUniqueness: ensureInitializerTypeUniqueness)
    }
}

// MARK: DelegationModifier

public struct DelegationModifier<C: Component, I: DelegatingHandlerInitializer>: Modifier {
    public typealias ModifiedComponent = C
    
    public let component: C
    private let initializer: I
    private let ensureInitializerTypeUniqueness: Bool

    fileprivate init(_ component: C, initializer: I, ensureInitializerTypeUniqueness: Bool = false) {
        self.component = component
        self.initializer = initializer
        self.ensureInitializerTypeUniqueness = ensureInitializerTypeUniqueness
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(
            DelegatingHandlerContextKey.self,
            value: [.init(initializer, ensureInitializerTypeUniqueness: ensureInitializerTypeUniqueness)],
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
    
    /// Build a partially type-erasured `Handler`-instance that delegates to the given `delegate`.
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

private extension AnyDelegatingHandlerInitializer {
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

public struct DelegatingHandlerContextKey: ContextKey {
    public typealias Value = OrderedSet<Entry>
    public static var defaultValue: Value = []

    public static func reduce(value: inout Value, nextValue: Value) {
        // append won't update members already in the original set (see `Entry.ensureInitializerTypeUniqueness`)
        value.append(contentsOf: nextValue)
    }
}

extension DelegatingHandlerContextKey {
    /// Represents the entry type for the value of an ``DelegatingHandlerContextKey``
    public struct Entry {
        /// Every entry of the ``DelegatingHandlerContextKey`` is identified by a instance specific
        /// `UUID` used to check if we already inserted into the ``Handler`` stack when parsing initializers.
        private let uuid: UUID

        /// The according ``AnyDelegatingHandlerInitializer`` used to instantiate the delegating ``Handler``.
        let initializer: AnyDelegatingHandlerInitializer
        /// If set to true, it is ensure that the same ``AnyDelegatingHandlerInitializer``, even though
        /// when inserted multiple times into the context, is only used a single time (the first time it got inserted).
        let ensureInitializerTypeUniqueness: Bool

        /// Creates a new ``Entry`` instance.
        /// - Parameters:
        ///   - initializer: The ``AnyDelegatingHandlerInitializer`` for the delegating Handler.
        ///   - ensureInitializerTypeUniqueness: If set to true, it is ensure that the same ``DelegatingHandlerInitializer``,
        ///     even though when inserted multiple times into the context, is only used a single time (the first time it got added).
        public init(_ initializer: AnyDelegatingHandlerInitializer, ensureInitializerTypeUniqueness: Bool = false) {
            self.uuid = UUID()
            self.initializer = initializer
            self.ensureInitializerTypeUniqueness = ensureInitializerTypeUniqueness
        }
    }
}

extension DelegatingHandlerContextKey.Entry: Hashable {
    public func hash(into hasher: inout Hasher) {
        if ensureInitializerTypeUniqueness {
            hasher.combine(initializer.id)
        } else {
            hasher.combine(uuid)
        }
    }

    public static func == (lhs: DelegatingHandlerContextKey.Entry, rhs: DelegatingHandlerContextKey.Entry) -> Bool {
        lhs.uuid == rhs.uuid ||
            (lhs.ensureInitializerTypeUniqueness == true && rhs.ensureInitializerTypeUniqueness == true && lhs.initializer.id == rhs.initializer.id)
    }
}
