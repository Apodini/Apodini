//
// Created by Andreas Bauer on 25.12.20.
//

#if DEBUG || RELEASE_TESTING
@testable import Apodini
import struct Foundation.UUID

// MARK: Mock Endpoint
public extension Handler {
    /// Creates a basic Endpoint Model from the `Handler`.
    /// If `Application` is defined, it will be injected into all `ApplicationInjectables`.
    /// - Note: This endpoint's identifier is not guaranteed to be stable
    func mockEndpoint(
        app: Application? = nil,
        context: Context? = nil,
        operation: Apodini.Operation? = nil,
        guards: [LazyGuard] = [],
        responseTransformers: [LazyAnyResponseTransformer] = []
    ) -> Endpoint<Self> {
        let context = context ?? Context(contextNode: ContextNode())
        var handler = self
        var guards = guards
        var responseTransformers = responseTransformers
        if let application = app {
            handler = handler.inject(app: application)
            guards = guards.inject(app: application)
            responseTransformers = responseTransformers.inject(app: application)
        }
        
        var blackboard: Blackboard
        if let application = app {
            blackboard = LocalBlackboard<LazyHashmapBlackboard, GlobalBlackboard<LazyHashmapBlackboard>>(
                GlobalBlackboard<LazyHashmapBlackboard>(application),
                using: handler,
                context)
        } else {
            blackboard = LocalBlackboard<LazyHashmapBlackboard, LazyHashmapBlackboard>(LazyHashmapBlackboard(), using: handler, context)
        }

        return Endpoint(
            handler: handler,
            blackboard: blackboard,
            guards: guards,
            responseTransformers: responseTransformers
        )
    }
}
#endif
