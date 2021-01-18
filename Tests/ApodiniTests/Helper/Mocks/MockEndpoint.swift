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
            operation: Operation = .automatic,
            guards: [LazyGuard] = [],
            responseTransformers: [LazyAnyResponseTransformer] = []
    ) -> Endpoint<Self> {
        let parameterBuilder = ParameterBuilder(from: self)
        parameterBuilder.build()
        return Endpoint(
            identifier: self.getExplicitlySpecifiedIdentifier() ?? AnyHandlerIdentifier(UUID().uuidString),
            handler: self,
            context: context,
            operation: operation,
            guards: guards,
            responseTransformers: responseTransformers,
            parameters: parameterBuilder.parameters
        )
    }

    func mockEndpoint(context: Context) -> Endpoint<Self> {
        mockEndpoint(context: context,
                     operation: .automatic,
                     guards: [],
                     responseTransformers: [])
    }
}
