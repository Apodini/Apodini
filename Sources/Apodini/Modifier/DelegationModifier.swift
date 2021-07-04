//
//  DelegatingHandlerInitializer.swift
//  
//
//  Created by Max Obermeier on 06.06.21.
//

import Foundation
import ApodiniUtils

// MARK: Component+DelegationModifier

extension Component {
    /// Use a `DelegatingHandlerInitializer` to create a fitting delegating `Handler` for each of the `Component`'s endpoints.
    /// All instances created by the `initializer` can delegate evaluations to their respective child-`Handler` using `Delegate`.
    /// - Parameter prepend: If set to `true`, the modifier is prepended to all other calls to `delegated` instead of being appended as usual.
    /// - Note: `prepend` should only be used if `I.Response` is `Self.Response` or `Self` is no `Handler`.
    public func delegated<I: DelegatingHandlerInitializer>(by initializer: I, prepend: Bool = false) -> DelegationModifier<Self, I> {
        DelegationModifier(self, initializer: initializer, prepend: prepend)
    }
}

// MARK: DelegationModifier

public struct DelegationModifier<C: Component, I: DelegatingHandlerInitializer>: Modifier {
    public typealias ModifiedComponent = C
    
    public let component: C
    private let initializer: I
    private let prepend: Bool
    
    fileprivate init(_ component: C, initializer: I, prepend: Bool = false) {
        self.component = component
        self.initializer = initializer
        self.prepend = prepend
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DelegatingHandlerContextKey.self, value: [(prepend, initializer)], scope: .environment)
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

public extension DelegatingHandlerInitializer {
    /// The default implementation for `anyinstance`, which erases the type of the `SomeHandler` returned
    /// by `.instance(for:)`.
    func anyinstance<D>(for delegate: D) throws -> AnyHandler where D: Handler {
        try instance(for: delegate).anyHandler
    }
}

// MARK: DelegatingHandlerContextKey

public struct DelegatingHandlerContextKey: ContextKey {
    public typealias Value = [(Bool, AnyDelegatingHandlerInitializer)]
    public static var defaultValue: Value = []
}
