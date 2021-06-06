//
//  DelegatingHandlerInitializer.swift
//  
//
//  Created by Max Obermeier on 06.06.21.
//

import Foundation
import ApodiniUtils

public protocol AnyDelegatingHandlerInitializer {
    func anyinstance<D: Handler>(for delegate: D) throws -> AnyHandler
    
    func evaluate(filter: DelegateFilter) -> Bool
}

public extension AnyDelegatingHandlerInitializer {
    func evaluate(filter: DelegateFilter) -> Bool {
        filter(self)
    }
}

public protocol DelegatingHandlerInitializer: AnyDelegatingHandlerInitializer {
    associatedtype Response: ResponseTransformable
    
    func instance<D: Handler>(for delegate: D) throws -> SomeHandler<Response>
}

public extension DelegatingHandlerInitializer {
    func anyinstance<D>(for delegate: D) throws -> AnyHandler where D : Handler {
        return try instance(for: delegate).anyHandler
    }
}

public protocol DelegateInitializable: Handler {
    init<D: Handler>(from delegate: D) throws
}

private struct DelegateInitializableInitializer<I: DelegateInitializable>: DelegatingHandlerInitializer {    
    func instance<D>(for delegate: D) throws -> SomeHandler<I.Response> where D : Handler {
        SomeHandler(try I(from: delegate))
    }
}

public extension DelegateInitializable {
    static var initializer: some DelegatingHandlerInitializer {
        DelegateInitializableInitializer<Self>()
    }
}

public protocol DelegateFilter {
    func callAsFunction<I: AnyDelegatingHandlerInitializer>(_ initializer: I) -> Bool
}

private struct AnyDelegateFilter: DelegatingHandlerInitializer, DelegateFilter {
    let filter: DelegateFilter
    
    func instance<D>(for delegate: D) throws -> SomeHandler<Never> where D : Handler {
        fatalError("AnyDelegateFilter was evaluated as normal AnyDelegatingHandlerInitializer")
    }
    
    func callAsFunction<I>(_ initializer: I) -> Bool where I : AnyDelegatingHandlerInitializer {
        filter(initializer)
    }
}

struct DelegatingHandlerContextKey: ContextKey {
    static var defaultValue: [AnyDelegatingHandlerInitializer] = []
    
    static func reduce(value: inout [AnyDelegatingHandlerInitializer], nextValue: () -> [AnyDelegatingHandlerInitializer]) {
        value.append(contentsOf: nextValue())
    }
}


public struct DelegateModifier<C: Component, I: DelegatingHandlerInitializer>: Modifier {
    public typealias ModifiedComponent = C
    
    public let component: C
    let initializer: I
    
    public var content: some Component { EmptyComponent() }
    
    init(_ component: C, initializer: I) {
        self.component = component
        self.initializer = initializer
    }
}

extension DelegateModifier: Handler, HandlerModifier where Self.ModifiedComponent: Handler {
    public typealias Response = I.Response
}

extension DelegateModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DelegatingHandlerContextKey.self, value: [initializer], scope: .environment)
        component.accept(visitor)
    }
}

public struct DelegateFilterModifier<C: Component>: Modifier {
    public typealias ModifiedComponent = C
    
    public let component: C
    private let filter: AnyDelegateFilter
    
    public var content: some Component { EmptyComponent() }
    
    fileprivate init(_ component: C, filter: AnyDelegateFilter) {
        self.component = component
        self.filter = filter
    }
}

extension DelegateFilterModifier: Handler, HandlerModifier where Self.ModifiedComponent: Handler {
    public typealias Response = C.Response
}

extension DelegateFilterModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DelegatingHandlerContextKey.self, value: [filter], scope: .environment)
        component.accept(visitor)
    }
}



extension Component {
    /// Use a `DelegatingHandlerInitializer` to create a fitting delegating `Handler` for each of the `Component`'s endpoints.
    /// All instances created by the `initializer` can delegate evaluations to their respective child-`Handler` using `Delegate`.
    public func delegated<I: DelegatingHandlerInitializer>(by initializer: I) -> DelegateModifier<Self, I> {
        DelegateModifier(self, initializer: initializer)
    }
}

extension Component {
    public func reset(using filter: DelegateFilter) -> DelegateFilterModifier<Self> {
        DelegateFilterModifier(self, filter: AnyDelegateFilter(filter: filter))
    }
}


class DelegatingHandlerInitializerVisitor: HandlerVisitor {
    var initializers: [AnyDelegatingHandlerInitializer]
    let semanticModelBuilder: SemanticModelBuilder
    let context: Context
    
    init(calling builder: SemanticModelBuilder, with context: Context, using initializers: [AnyDelegatingHandlerInitializer]) {
        self.initializers = initializers
        self.semanticModelBuilder = builder
        self.context = context
    }
    
    func visit<H: Handler>(handler: H) throws {
        preconditionTypeIsStruct(H.self, messagePrefix: "Delegating Handler")
        if !initializers.isEmpty {
            let initializer = initializers.removeFirst()
            
            if let filter = initializer as? DelegateFilter {
                initializers = initializers.filter { initializerToFilter in
                    initializerToFilter.evaluate(filter: filter)
                }
            } else {
                let nextHandler = try initializer.anyinstance(for: handler)
                try nextHandler.accept(self)
            }
        } else {
            semanticModelBuilder.register(handler: handler, withContext: context)
        }
    }
}
