//
// Created by Andreas Bauer on 16.01.21.
//

/// Every `Endpoint` is uniquely identified by its path and `Operation`
/// and thus can be reference by this information.
struct EndpointReference: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String {
        "Endpoint(operation: \(operation), at: \(absolutePath.asPathString())}"
    }
    var debugDescription: String {
        "Endpoint<\(resolve().description)>(operation: \(operation), at: \(absolutePath.asPathString()))"
    }

    let webservice: WebServiceModel

    /// The absolute path to the `Endpoint` (containing .root as the first element)
    /// The absolutePath MUST be scoped to the reference Endpoint.
    let absolutePath: [EndpointPath]
    /// The operation of the `Endpoint`
    let operation: Operation
    /// Holds the response type of the `Endpoint`
    let responseType: Any.Type

    /// Resolve the referenced `Endpoint`
    ///
    /// - Returns: The instance of `AnyEndpoint` this `EndpointReference` references to.
    func resolve() -> _AnyEndpoint {
        webservice.resolve(self)
    }

    func resolveAndMutate(_ mutate: (inout _AnyEndpoint) -> Void) {
        webservice.resolveAndMutate(self, mutate)
    }

    internal func resolveNode() -> EndpointsTreeNode {
        webservice.resolveNode(self)
    }
}

extension EndpointReference: Hashable {
    static func == (lhs: EndpointReference, rhs: EndpointReference) -> Bool {
        lhs.absolutePath == rhs.absolutePath && lhs.operation == rhs.operation
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(absolutePath)
        hasher.combine(operation)
    }
}
