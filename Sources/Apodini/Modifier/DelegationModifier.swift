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
    
    public var content: some Component { EmptyComponent() }
    
    fileprivate init(_ component: C, initializer: I, prepend: Bool = false) {
        self.component = component
        self.initializer = initializer
        self.prepend = prepend
    }
}

extension DelegationModifier: HandlerModifier where Self.ModifiedComponent: Handler {
    public typealias Response = I.Response
}

extension DelegationModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(DelegatingHandlerContextKey.self, value: [(prepend, initializer)], scope: .environment)
        component.accept(visitor)
    }
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
    
    /// Build a paritally type-erasured `Handler`-instance that delegates to the given `delegate`.
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

struct DelegatingHandlerContextKey: ContextKey {
    static var defaultValue: [(Bool, AnyDelegatingHandlerInitializer)] = []
    
    static func reduce(value: inout [(Bool, AnyDelegatingHandlerInitializer)], nextValue: () -> [(Bool, AnyDelegatingHandlerInitializer)]) {
        value.append(contentsOf: nextValue())
    }
}


// MARK: DelegatingHandlerInitializerVisitor

class DelegatingHandlerInitializerVisitor: HandlerVisitor {
    var initializers: [AnyDelegatingHandlerInitializer]
    let semanticModelBuilder: SemanticModelBuilder?
    unowned let visitor: SyntaxTreeVisitor
    
    init(calling builder: SemanticModelBuilder?, with visitor: SyntaxTreeVisitor) {
        let initializers = visitor.currentNode.getContextValue(for: DelegatingHandlerContextKey.self)
        self.initializers = (initializers.filter { prepend, _ in prepend }.reversed()
                                + initializers.filter { prepend, _ in !prepend }).map { _, initializer in initializer }
        self.semanticModelBuilder = builder
        self.visitor = visitor
    }
    
    func visit<H: Handler>(handler: H) throws {
        preconditionTypeIsStruct(H.self, messagePrefix: "Delegating Handler")
        
        handler.metadata.accept(visitor)
        
        if !initializers.isEmpty {
            let initializer = initializers.removeFirst()
            
            if let filter = initializer as? DelegationFilter {
                initializers = initializers.filter { initializerToFilter in
                    initializerToFilter.evaluate(filter: filter)
                }
                try visit(handler: handler)
            } else {
                let nextHandler = try initializer.anyinstance(for: handler)
                try nextHandler.accept(self)
            }
        } else {
            // We capture the currentContextNode and make a copy that will be used when executing the request as
            // directly capturing the currentNode would be influenced by the `resetContextNode()` call and using the
            // currentNode would always result in the last currentNode that was used when visiting the component tree.
            let context = Context(contextNode: visitor.currentNode.copy())
            
            semanticModelBuilder?.register(handler: handler, withContext: context)
        }
    }
}
