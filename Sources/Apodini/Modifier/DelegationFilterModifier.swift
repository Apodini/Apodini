//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

// MARK: Component+DelegationFilterModifier

extension Component {
    /// Use a `DelegationFilter` to filter out `DelegatingHandlerInitializer`s for the contained sub-tree.
    /// - Parameter prepend: If set to `true`, the modifier is prepended to all other calls to `reset` or `delegated`
    ///                      instead of being appended as usual.
    /// - Note: `prepend` should only be used if `I.Response` is `Self.Response` or `Self` is no `Handler`.
    public func reset(using filter: DelegationFilter, prepend: Bool = false) -> DelegationFilterModifier<Self> {
        DelegationFilterModifier(self, filter: AnyDelegateFilter(filter: filter), prepend: prepend)
    }
}


// MARK: DelegationFilterModifier

public struct DelegationFilterModifier<C: Component>: Modifier {
    public typealias ModifiedComponent = C
    
    public let component: C
    private let filter: AnyDelegateFilter
    private let prepend: Bool
    
    public var content: some Component { EmptyComponent() }
    
    fileprivate init(_ component: C, filter: AnyDelegateFilter, prepend: Bool = false) {
        self.component = component
        self.filter = filter
        self.prepend = prepend
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DelegatingHandlerContextKey.self, value: [(prepend, filter)], scope: .environment)
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

private struct AnyDelegateFilter: DelegatingHandlerInitializer, DelegationFilter {
    let filter: DelegationFilter
    
    func instance<D>(for delegate: D) throws -> SomeHandler<Never> where D: Handler {
        fatalError("AnyDelegateFilter was evaluated as normal AnyDelegatingHandlerInitializer")
    }
    
    func callAsFunction<I>(_ initializer: I) -> Bool where I: AnyDelegatingHandlerInitializer {
        filter(initializer)
    }
}
