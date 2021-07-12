//
//  DelegationFilterModifier.swift
//  
//
//  Created by Max Obermeier on 06.06.21.
//

import Foundation

// MARK: Component+DelegationFilterModifier

extension Component {
    /// Use a `DelegationFilter` to filter out `DelegatingHandlerInitializer`s for the contained sub-tree.
    /// - Parameters:
    ///   - ensureInitializerTypeUniqueness: If set to true, it is ensured that the same ``DelegationFilter``
    ///     is only used a single time, even when inserted multiple times.
    public func reset(using filter: DelegationFilter, ensureInitializerTypeUniqueness: Bool = false) -> DelegationFilterModifier<Self> {
        DelegationFilterModifier(self, filter: AnyDelegateFilter(filter: filter), ensureInitializerTypeUniqueness: ensureInitializerTypeUniqueness)
    }
}


// MARK: DelegationFilterModifier

public struct DelegationFilterModifier<C: Component>: Modifier {
    public typealias ModifiedComponent = C
    
    public let component: C
    private let entry: DelegatingHandlerContextKey.Entry
    
    fileprivate init(_ component: C, filter: AnyDelegateFilter, ensureInitializerTypeUniqueness: Bool = false, inverseOrder: Bool = false) {
        self.component = component
        self.entry = .init(filter, ensureInitializerTypeUniqueness: ensureInitializerTypeUniqueness, inverseOrder: inverseOrder)
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(
            DelegatingHandlerContextKey.self,
            value: [entry],
            scope: .environment
        )
    }
}

extension DelegationFilterModifier: HandlerModifier where Self.ModifiedComponent: Handler {
    public typealias Response = C.Response
}


// MARK: DelegationFilter

/// A `DelegationFilter` tells the framework whether or not to ignore a certain `initializer` in a certain context.
public protocol DelegationFilter {
    /// A function that represents the filter. Return `false` if the `initializer` should be **ignored**.
    func callAsFunction<I: AnyDelegatingHandlerInitializer>(_ initializer: I) -> Bool
}

struct AnyDelegateFilter: DelegatingHandlerInitializer, DelegationFilter {
    let filter: DelegationFilter
    
    func instance<D>(for delegate: D) throws -> SomeHandler<Never> where D: Handler {
        fatalError("AnyDelegateFilter was evaluated as normal AnyDelegatingHandlerInitializer")
    }
    
    func callAsFunction<I>(_ initializer: I) -> Bool where I: AnyDelegatingHandlerInitializer {
        filter(initializer)
    }
}
