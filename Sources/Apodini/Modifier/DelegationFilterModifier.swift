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
    /// - Parameter ensureInitializerTypeUniqueness: If set to true, it is ensure that the same ``DelegationFilter``,
    ///     even though when inserted multiple times into the context, is only used a single time (the first time it got added).
    public func reset(using filter: DelegationFilter, ensureInitializerTypeUniqueness: Bool = false) -> DelegationFilterModifier<Self> {
        DelegationFilterModifier(self, filter: AnyDelegateFilter(filter: filter), ensureInitializerTypeUniqueness: ensureInitializerTypeUniqueness)
    }
}


// MARK: DelegationFilterModifier

public struct DelegationFilterModifier<C: Component>: Modifier {
    public typealias ModifiedComponent = C
    
    public let component: C
    private let filter: AnyDelegateFilter
    private let ensureInitializerTypeUniqueness: Bool
    
    fileprivate init(_ component: C, filter: AnyDelegateFilter, ensureInitializerTypeUniqueness: Bool = false) {
        self.component = component
        self.filter = filter
        self.ensureInitializerTypeUniqueness = ensureInitializerTypeUniqueness
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(
            DelegatingHandlerContextKey.self,
            value: [.init(filter, ensureInitializerTypeUniqueness: ensureInitializerTypeUniqueness)],
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
