//
// Created by Andreas Bauer on 10.01.21.
//

/// Defines a representation for a `WebService` that is used to build up and present relationship-information.
public class RelationshipWebServiceModel: CustomDebugStringConvertible {
    public var debugDescription: String {
        root.debugDescription
    }

    // class as it is used as a reference in `EndpointReference`
    internal let root = EndpointsTreeNode(storedPath: .root)

    private var rootEndpoints: [Operation: AnyRelationshipEndpoint] = [:]
    private lazy var structuralRootRelationships: [EndpointRelationship] = {
        guard finishedParsing else {
            fatalError("Tried retrieving root relationships before WebService was finished parsing!")
        }

        return Array(RelationshipBuilder.constructStructuralRelationships(for: root).values)
    }()

    private var finishedParsing = false
    
    public let globalBlackboard: Blackboard

    init(_ globalBlackboard: Blackboard) {
        self.globalBlackboard = globalBlackboard
    }

    /// Retrieve the `RelationshipEndpoint` located under the `EndpointPath.root`.
    /// - Parameter operation: The `Operation` to retrieve the `RelationshipEndpoint` for.
    /// - Returns: The `AnyRelationshipEndpoint` or nil if it doesn't exist.
    public func getEndpoint(for operation: Operation) -> AnyRelationshipEndpoint? {
        rootEndpoints[operation]
    }

    /// Shortcut for calling `relationships(endpoint: operation, for: operation)`
    /// - Parameter operation: Defines the `Operation` for the root `RelationshipEndpoint`
    ///     AND for the `RelationshipDestination`s to be retrieved from that endpoint.
    /// - Returns: The set of `RelationshipDestination`. If the `Endpoint` doesn't exist
    ///     default structural relationships are returned.
    public func rootRelationships(for operation: Operation) -> Set<RelationshipDestination> {
        rootRelationships(endpoint: operation, for: operation)
    }

    /// Creates a `Set<RelationshipDestination` which ensures that relationship names
    /// are unique (for all collected destination for: a given `Operation`).
    /// The relationships are retrieved for a certain `RelationshipEndpoint` defined by the given `Operation`.
    /// If the `Endpoint` doesn't exist  default structural relationships are returned,
    /// being the main difference over `getEndpoint(for: endpointOperation)?.relationships(for: relationshipOperation)`.
    ///
    /// - Parameters:
    ///   - endpoint: The `Operation` of the `RelationshipEndpoint` to retrieve the Relationships from.
    ///   - operation: The `Operation` of the Relationship destination to create a unique set for.
    /// - Returns: The set of uniquely named relationship destinations. If the `RelationshipEndpoint` doesn't exist
    ///     default structural relationships are returned.
    public func rootRelationships(endpoint: Operation, for operation: Operation) -> Set<RelationshipDestination> {
        if let endpoint = rootEndpoints[endpoint] {
            return endpoint.relationships(for: operation)
        }
        return structuralRootRelationships.unique(for: operation)
    }

    func finish() {
        finishedParsing = true
        root.finish()
        rootEndpoints = root.endpoints
    }

    func addEndpoint<H: Handler>(_ endpoint: inout RelationshipEndpoint<H>, at paths: [PathComponent]) {
        var context = EndpointInsertionContext(for: endpoint, with: paths)
        context.assertRootPath()
        root.addEndpoint(&endpoint, context: &context)
    }
}
