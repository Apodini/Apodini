//
// Created by Andi on 25.12.20.
//

@testable import Apodini
import struct Foundation.UUID

// MARK: Mock Endpoint
extension Handler {
    /// Creates a basic Endpoint Model from the `Handler`.
    /// - Note: This endpoint's identifier is not guaranteed to be stable
    func mockEndpoint(
        context: Context = Context(contextNode: ContextNode()),
        operation: Operation? = nil,
        guards: [LazyGuard] = [],
        responseTransformers: [LazyAnyResponseTransformer] = []
    ) -> Endpoint<Self> {
        Endpoint(
            identifier: self.getExplicitlySpecifiedIdentifier() ?? AnyHandlerIdentifier(UUID().uuidString),
            handler: self,
            context: context,
            operation: operation,
            guards: guards,
            responseTransformers: responseTransformers
        )
    }
    
    /// Creates a basic Endpoint Model from the `Handler` and injects an `app` instance to all `ApplicationInjectables`.
    /// - Note: This endpoint's identifier is not guaranteed to be stable
    func mockEndpoint(
        app: Application,
        context: Context = Context(contextNode: ContextNode()),
        operation: Operation? = nil,
        guards: [LazyGuard] = [],
        responseTransformers: [LazyAnyResponseTransformer] = []
    ) -> Endpoint<Self> {
        Endpoint(
            identifier: self.getExplicitlySpecifiedIdentifier() ?? AnyHandlerIdentifier(UUID().uuidString),
            handler: self.inject(app: app),
            context: context,
            operation: operation,
            guards: guards,
            responseTransformers: responseTransformers
        )
    }
}
