//
// Created by Andreas Bauer on 25.12.20.
//

/// Models relationships of a `Endpoint` to (multiple) destination `Endpoint`s,
/// which all are located under the same path.
public struct EndpointRelationship: Equatable {
    /// Absolut path to the Relationship destinations
    /// Internal as this path isn't scoped to a destination `Endpoint`.
    /// On self relationship this path always reflects the path of the original `Endpoint`
    /// and destinations might contain destinations under a different path.
    let path: [EndpointPath]

    /// Destinations indexed by the Operation of the `Endpoint`.
    /// There will be at least one destination.
    /// There is not guarantee that all Relationship destinations
    /// defined under the same path are contained withing the same `EndpointRelationship`.
    /// (e.g. Relationships added through `Relationship` instances).
    fileprivate var relationshipDestinations: [Operation: RelationshipDestination] = [:]

    /// Holds all `RelationshipDestinations` registered under the particular `EndpointRelationship`.
    public var destinations: [RelationshipDestination] {
        Array(relationshipDestinations.values)
    }

    /// Initializes a new `EndpointRelationship` under the unscoped path.
    /// - Parameter path: Unscoped path of destination of the `EndpointRelationship`
    init(path: [EndpointPath]) {
        self.path = path
    }

    /// Initializes a new `EndpointRelationship` with a existing `RelationshipDestination`.
    init(destination: RelationshipDestination) {
        self.init(path: destination.destinationPath.unscoped())
        self.add(destination: destination)
    }

    /// Retrieves a `RelationshipDestination`.
    /// There will be at least one destination on every `EndpointRelationship` instance.
    ///
    /// - Parameter operation: The option to search for a `RelationshipDestination`.
    /// - Returns: Returns a `RelationshipDestination` for a given `Operation` or nil if it doesn't exists.
    public func get(for operation: Operation) -> RelationshipDestination? {
        relationshipDestinations[operation]
    }

    /// Adds a new `RelationshipDestination` to the given `EndpointRelationship` for a given destination `Endpoint`.
    /// The relationship added through this is considered a "structural" Relationship (derived from the PathComponent structure)
    ///
    /// - Parameters:
    ///   - endpoint: The destination for the relationship.
    ///   - prefix: Prefix to prepend to the relationship name.
    ///   - relativeNamingPath: The relative path to use for naming.
    ///   - nameOverride: Optional override for the relationship name.
    ///   - hideLink: Flag defining if the Relationship link should be hidden.
    mutating func addEndpoint(
        _ endpoint: _AnyRelationshipEndpoint,
        prefix: String,
        relativeNamingPath: [EndpointPath],
        nameOverride: String? = nil,
        hideLink: Bool = false) {
        precondition(path == endpoint.absolutePath,
                     "Tried adding endpoint to relationship \(path.asPathString()) located under different \(endpoint.absolutePath.asPathString())")

        relationshipDestinations[endpoint[Operation.self]] = RelationshipDestination(
            name: prefix + (nameOverride ?? relativeNamingPath.scoped(on: endpoint).build(with: RelationshipNameBuilder.self)),
            endpoint: endpoint,
            absolutePath: endpoint.absolutePath,
            hideLink: hideLink
        )
    }

    /// Adds a new `RelationshipDestination` to the given `EndpointRelationship` for a given destination `Endpoint` and name.
    /// This call is the result of a defined `Relationship` instance (or its parsed variant `RelationshipInstance`).
    ///
    /// - Parameters:
    ///   - endpoint: The destination Endpoint of the Relationship.
    ///   - name: The name for the Relationship.
    mutating func addEndpoint(_ endpoint: _AnyRelationshipEndpoint, name: String) {
        precondition(path == endpoint.absolutePath,
                     "Tried adding endpoint to relationship \(path.asPathString()) located under different \(endpoint.absolutePath.asPathString())")

        relationshipDestinations[endpoint[Operation.self]] = RelationshipDestination(
            name: name,
            endpoint: endpoint,
            absolutePath: endpoint.absolutePath,
            hideLink: false
        )
    }

    mutating func addEndpoint(self endpoint: _AnyRelationshipEndpoint) {
        addEndpoint(endpoint, name: "self")
    }

    /// Internal method to merge two `EndpointRelationship` instances located under the same path.
    /// Any destination contained in the self `EndpointRelationship` will be overridden by destination of
    /// the provided `EndpointRelationship` should there be conflicting definitions for a certain `Operation`.
    ///
    /// Thus this method must be evaluated with care. As those would represent the same relationship destination,
    /// the only thing overwritten is relationship naming. Thus `merge` should be used in a way where e.g.
    /// a generate relationship name should be overwritten by a user defined name.
    ///
    /// - Parameter relationship: The `EndpointRelationship` to merge with.
    mutating func merge(with relationship: EndpointRelationship) {
        precondition(path == relationship.path, "Tried merging relationships located under dissimilar paths")

        for (operation, destination) in relationship.relationshipDestinations {
            relationshipDestinations[operation] = destination
        }
    }

    /// Internal method to add a given `RelationshipDestination` to the `EndpointRelationship`.
    /// Should the relationship already contain the destination (for the given Operation) it will
    /// be overridden by the supplied destination (meaning naming will be overridden).
    /// - Parameter destination: `RelationshipDestination` to be added.
    mutating func add(destination: RelationshipDestination) {
        precondition(path == destination.destinationPath, "Tried adding a relationship destination under a wrong path.")
        if relationshipDestinations[destination.operation] != nil {
            return
        }
        relationshipDestinations[destination.operation] = destination
    }

    mutating func replaceAll(resolvers: [AnyPathParameterResolver]) {
        for operation in relationshipDestinations.keys {
            relationshipDestinations[operation]?.replace(resolvers: resolvers)
        }
    }

    public static func == (lhs: EndpointRelationship, rhs: EndpointRelationship) -> Bool {
        lhs.path == rhs.path
    }
}

/// Models one of multiple destinations for a given `EndpointRelationship`.
public struct RelationshipDestination: CustomStringConvertible, Hashable {
    public var description: String {
        "RelationshipDestination(name: \(name), at: \(operation) \(destinationPath.asPathString()))"
    }

    /// Name of the destination.
    public let name: String

    /// The `EndpointReference` to the relationship destination.
    let reference: EndpointReference

    public let operation: Operation
    /// The path of the destination.
    /// The paths of all destinations on the same `EndpointRelationship` are equal in the sense
    /// that they point to the same destination in the Component tree.
    /// However this property is scoped to this specific `Endpoint`, meaning naming
    /// of parameters will be derived by this specific `Endpoint`.
    /// See `AnyEndpointPathParameter.scoped(on endpoint: AnyEndpoint)`.
    public private(set) var destinationPath: [EndpointPath]
    /// For Exporter representing a Relationship using Links (e.g. REST with HATEOAS),
    /// this property defines if such a link may be hidden.
    /// The destination of the Relationship must still be accessible fore requests
    /// directly pointed to the `Endpoint`.
    public let hideLink: Bool

    /// Contains PathParameter resolvers for the destinationPath. Could contain duplicates.
    private(set) var resolvers: [AnyPathParameterResolver]

    /// Initializes the special "self" Relationship for a given EndpointReference
    init(self reference: EndpointReference, resolvers: [AnyPathParameterResolver]) {
        self.name = "self"
        self.reference = reference
        self.operation = reference.operation
        self.destinationPath = reference.absolutePath // already scoped
        self.hideLink = false
        self.resolvers = resolvers
    }

    /// Initializes a destination from a .reference or .link relationship candidate
    init(name: String, destination reference: EndpointReference, resolvers: [AnyPathParameterResolver]) {
        self.name = name
        self.reference = reference
        self.operation = reference.operation
        self.destinationPath = reference.absolutePath // already scoped
        self.hideLink = false
        self.resolvers = resolvers
    }

    /// Initializer to create structural Relationships or relationships derived from `Relationship` instances.
    fileprivate init(
        name: String,
        endpoint: _AnyRelationshipEndpoint,
        absolutePath: [EndpointPath],
        hideLink: Bool
    ) {
        self.name = name
        self.reference = endpoint.reference
        self.operation = endpoint[Operation.self]
        self.destinationPath = absolutePath
        self.hideLink = hideLink
        // only information for parameter resolvers are our own path
        self.resolvers = absolutePath.listPathParameters().resolvers()
    }

    /// Resolves any path parameters contained in the `destinationPath` if
    /// there is a resolver and a value for it.
    internal mutating func resolveParameters(context: ResolveContext) {
        destinationPath = destinationPath.map { path in
            if case let .parameter(parameter) = path {
                var parameter = parameter.toInternal()
                if let resolver = resolvers.first(where: { $0.resolves(parameter: parameter) }),
                   let value = resolver.resolve(context: context) {
                    // creates resolved version of the EndpointPathParameter
                    parameter.resolved(value: value)
                }

                return .parameter(parameter)
            }

            return path
        }
    }

    mutating func replace(resolvers parameterResolvers: [AnyPathParameterResolver]) {
        self.resolvers = parameterResolvers
    }

    public func hash(into hasher: inout Hasher) {
        name.hash(into: &hasher)
        operation.hash(into: &hasher)
    }

    public static func == (lhs: RelationshipDestination, rhs: RelationshipDestination) -> Bool {
        lhs.name == rhs.name && lhs.operation == rhs.operation
    }
}


private struct RelationshipNameBuilder: PathBuilderWithResult {
    var name: [String] = []

    mutating func append(_ string: String) {
        name.append(string)
    }

    mutating func append<Type: Codable>(_ parameter: EndpointPathParameter<Type>) {
        // typical relative paths are `user/:userId`. A sensible name for such a relationship
        // would be "user", thus we not include the parameter name if it isn't need to prevent
        // and empty name e.g.
        if name.isEmpty {
            name.append(parameter.name)
        }
    }

    func result() -> String {
        name.joined(separator: "_")
    }
}


extension Array where Element == EndpointRelationship {
    func replaceAll(resolvers: [AnyPathParameterResolver]) -> [EndpointRelationship] {
        map { entry in
            var relationship = entry
            relationship.replaceAll(resolvers: resolvers)
            return relationship
        }
    }
}

extension Array where Element == EndpointRelationship {
    /// Creates a `Set<RelationshipDestination` which ensures that relationship names are unique.
    func unique() -> Set<RelationshipDestination> {
        reduce(into: Set()) { result, relationship in
            for destination in relationship.destinations {
                result.update(with: destination)
            }
        }
    }

    /// Creates a `Set<RelationshipDestination` which ensures that relationship names
    /// are unique (for all collected destination for a given `Operation`)
    func unique(for operation: Operation) -> Set<RelationshipDestination> {
        reduce(into: Set()) { result, relationship in
            if let destination = relationship.get(for: operation) {
                result.update(with: destination)
            }
        }
    }
}
