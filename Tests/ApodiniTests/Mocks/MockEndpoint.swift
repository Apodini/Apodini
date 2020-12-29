//
// Created by Andi on 25.12.20.
//

@testable import Apodini

// MARK: Mock Endpoint
extension Component {
    /// Creates a basic Endpoint Model from the `Component`.
    func mockEndpoint(
            context: Context = Context(contextNode: ContextNode()),
            operation: Operation = .automatic,
            guards: [LazyGuard] = [],
            responseTransformers: [() -> (AnyResponseTransformer)] = []
    ) -> Endpoint<Self> {
        let parameterBuilder = ParameterBuilder(from: self)
        parameterBuilder.build()
        return Endpoint(
                component: self,
                context: context,
                operation: operation,
                guards: guards,
                responseTransformers: responseTransformers,
                parameters: parameterBuilder.parameters
        )
    }
}
