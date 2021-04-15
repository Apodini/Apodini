//
// Created by Andreas Bauer on 25.12.20.
//

@testable import Apodini
import struct Foundation.UUID

// MARK: Mock Endpoint
extension Handler {
    /// Creates a basic Endpoint Model from the `Handler`.
    /// If `Application` is defined, it will be injected into all `ApplicationInjectables`.
    /// - Note: This endpoint's identifier is not guaranteed to be stable
    func mockEndpoint(
        app: Application? = nil,
        context: Context = Context(contextNode: ContextNode()),
        operation: Operation? = nil,
        guards: [LazyGuard] = [],
        responseTransformers: [LazyAnyResponseTransformer] = []
    ) -> Endpoint<Self> {
        var handler = self
        var guards = guards
        var responseTransformers = responseTransformers
        if let application = app {
            handler = handler.inject(app: application)
            guards = guards.inject(app: application)
            responseTransformers = responseTransformers.inject(app: application)
        }

        return Endpoint(
            handler: handler,
            content: try! ContentModuleStore(for: handler, using: context),
            context: context,
            guards: guards,
            responseTransformers: responseTransformers
        )
    }
}
