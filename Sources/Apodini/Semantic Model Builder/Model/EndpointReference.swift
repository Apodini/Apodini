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

    let node: EndpointsTreeNode

    /// The absolute path to the `Endpoint` (containing .root as the first element)
    /// The absolutePath MUST be scoped to the reference Endpoint.
    let absolutePath: [EndpointPath]
    /// The operation of the `Endpoint`
    let operation: Operation
    /// Holds the response type of the `Endpoint`
    let responseType: Any.Type

    init<H: Handler>(on node: EndpointsTreeNode, off endpoint: Endpoint<H>) {
        self.node = node
        self.absolutePath = endpoint.absolutePath
        self.operation = endpoint[Operation.self]
        self.responseType = endpoint[ResponseType.self].type
    }

    /// Resolve the referenced `Endpoint`
    /// - Returns: The instance of `AnyEndpoint` this `EndpointReference` references to.
    func resolve() -> _AnyEndpoint {
        guard let endpoint = node.endpoints[operation] else {
            fatalError("Failed to resolve Endpoint at \(absolutePath.asPathString()): Didn't find Endpoint with operation \(operation)")
        }
        return endpoint
    }

    /// Mutates the reference `Endpoint`
    /// - Parameter mutate: The closure mutating the referenced `Endpoint`.
    func resolveAndMutate(_ mutate: @escaping (inout _AnyEndpoint) -> Void) {
        var endpoint = resolve()
        mutate(&endpoint)
        node.endpoints[operation] = endpoint
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

class ReferenceModule: DependencyBased {
    static var dependencies: [ContentModule.Type] = []
    
    var reference: EndpointReference {
        guard let r = _reference else {
            fatalError("ReferenceModule was used before the reference was injected by the framework!")
        }
        return r
    }
    
    private var _reference: EndpointReference?
    
    required init(from store: ModuleStore) throws { }
    
    func inject(reference: EndpointReference) {
        self._reference = reference
    }
}
