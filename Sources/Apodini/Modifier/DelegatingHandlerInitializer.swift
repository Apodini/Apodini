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


extension Component {
    /// Use a `DelegatingHandlerInitializer` to create a fitting delegating `Handler` for each of the `Component`'s endpoints.
    /// All instances created by the `initializer` can delegate evaluations to their respective child-`Handler` using `Delegate`.
    public func delegated<I: DelegatingHandlerInitializer>(by initializer: I) -> DelegateModifier<Self, I> {
        DelegateModifier(self, initializer: initializer)
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
            let nextHandler = try initializer.anyinstance(for: handler)
            try nextHandler.accept(self)
        } else {
            semanticModelBuilder.register(handler: handler, withContext: context)
        }
    }
}
