//
// Created by Andreas Bauer on 21.01.21.
//

import Foundation

struct EndpointInsertionContext {
    private let endpoint: AnyEndpoint
    private(set) var storedPath: [StoredEndpointPath]

    /// This array holds all UUIDs of Parameters which were already retrieved from the path array above.
    /// This is used to decide if we need to add a PathParameter which has a definition in the Handler
    /// but not a dedicated definition contained in the PathComponents
    private var retrievedParameters: [UUID] = []

    var pathEmpty: Bool {
        storedPath.isEmpty
    }
    var pathCount: Int {
        storedPath.count
    }

    init(for endpoint: AnyEndpoint, with pathComponents: [PathComponent]) {
        self.endpoint = endpoint
        self.storedPath = pathComponents.pathModelBuilder().results
    }

    func retrievedPathContains(parameter: AnyEndpointParameter) -> Bool {
        retrievedParameters.contains(parameter.id)
    }

    mutating func append(parameter: AnyEndpointParameter) {
        storedPath.append(StoredEndpointPath(
            path: parameter.toInternal().derivePathParameterModel()
        ))
    }

    mutating func assertRootPath() {
        storedPath.assertRoot()
    }

    mutating func nextStoredPath() -> StoredEndpointPath {
        let next = storedPath.removeFirst()

        if case let .parameter(parameter) = next.path {
            precondition(!retrievedParameters.contains(parameter.id), {
                var parameter = parameter.toInternal()
                parameter.scoped(on: endpoint)
                return "The path of \(endpoint.description) contains duplicated path parameter : \(parameter.name)!"
            }())

            retrievedParameters.append(parameter.id)
        }

        return next
    }
}

class EndpointsTreeNode {
    let storedPath: StoredEndpointPath
    var endpoints: [Operation: _AnyEndpoint] = [:]

    let parent: EndpointsTreeNode?
    private var nodeChildren: [EndpointPath: EndpointsTreeNode] = [:]
    var children: Dictionary<EndpointPath, EndpointsTreeNode>.Values {
        nodeChildren.values
    }
    /// If a EndpointsTreeNode A is a child to  a EndpointsTreeNode B and A has an `PathParameter` as its `path`
    /// B can't have any other children besides A that also have an `PathParameter` at the same location.
    /// Thus we mark `childContainsPathParameter` to true as soon as we insert a `PathParameter` as a child.
    private var childContainsPathParameter = false

    private var finishedConstruction = false

    lazy var absolutePath: [EndpointPath] = {
        var absolutePath: [EndpointPath] = []
        collectAbsolutePath(&absolutePath)
        return absolutePath
    }()

    init(storedPath: StoredEndpointPath, parent: EndpointsTreeNode? = nil) {
        self.storedPath = storedPath
        self.parent = parent
    }

    /// This method is called once the tree structure is built completely.
    /// At this point one can safely construct any relationships between nodes.
    func finish() {
        finishedConstruction = true

        // those are all the same independent of the source Endpoint
        let structuralRelationships = constructStructuralRelationships()
        let structuralSelfRelationship = constructStructuralSelfRelationship()

        for key in endpoints.keys {
            endpoints[key]?.finished(with: structuralRelationships, self: structuralSelfRelationship)
        }

        for child in children {
            child.finish()
        }
    }

    func addEndpoint<H: Handler>(_ endpoint: inout Endpoint<H>, context: inout EndpointInsertionContext) {
        if context.pathEmpty {
            for parameter in endpoint.parameters {
                // when the parameter is type of .path and not contained in our path, we must append it to our path
                if parameter.parameterType == .path && !context.retrievedPathContains(parameter: parameter) {
                    context.append(parameter: parameter)
                }
            }

            if !context.pathEmpty { // we added some additional parameters, see above
                return addEndpoint(&endpoint, context: &context)
            }

            // swiftlint:disable:next force_unwrapping
            precondition(endpoints[endpoint.operation] == nil, "Tried overwriting endpoint \(endpoints[endpoint.operation]!.description) with \(endpoint.description) for operation \(endpoint.operation)")
            precondition(!endpoint.inserted, "The endpoint \(endpoint.description) is already inserted at some different place")

            endpoint.inserted(at: self)
            endpoints[endpoint.operation] = endpoint
        } else {
            let next = context.nextStoredPath()
            var child = nodeChildren[next.path]

            if child == nil {
                // as we create a new child node we need to check if there are colliding path parameters
                if case .parameter = next.path {
                    // check that there isn't already some children with a path parameter on this level
                    precondition(!childContainsPathParameter,
                                 """
                                 When inserting endpoint \(endpoint.description) we encountered a path parameter collision \
                                 on level n-\(context.pathCount): You can't have multiple path parameters on the same level!
                                 """)

                    childContainsPathParameter = true
                }

                child = EndpointsTreeNode(storedPath: next, parent: self)
                nodeChildren[next.path] = child
            }

            // swiftlint:disable:next force_unwrapping
            child!.addEndpoint(&endpoint, context: &context)
        }
    }

    // See `EndpointReference`
    func resolve(_ path: inout [EndpointPath], _ operation: Operation) -> _AnyEndpoint {
        let node = resolveNode(&path)
        guard let endpoint = node.endpoints[operation] else {
            fatalError("Failed to resolve Endpoint at \(absolutePath.asPathString()): Didn't find Endpoint with operation \(operation)")
        }
        return endpoint
    }

    // See `EndpointReference`
    func resolveAndMutate(_ path: inout [EndpointPath], _ operation: Operation, _ mutate: (inout _AnyEndpoint) -> Void) {
        let node = resolveNode(&path)
        guard var endpoint = node.endpoints[operation] else {
            fatalError("Failed to resolve Endpoint at \(absolutePath.asPathString()): Didn't find Endpoint with operation \(operation)")
        }

        mutate(&endpoint)
        node.endpoints[operation] = endpoint
    }

    // See `EndpointReference`
    func resolveNode(_ path: inout [EndpointPath]) -> EndpointsTreeNode {
        if path.isEmpty {
            return self
        }

        let next = path.removeFirst()
        guard let child = nodeChildren[next] else {
            fatalError("Failed to resolve Endpoint at \(absolutePath.asPathString()): Couldn't continue to resolve \(next.description)+\(path.asPathString()).")
        }

        return child.resolveNode(&path)
    }

    private func collectAbsolutePath(_ absolutePath: inout [EndpointPath]) {
        if let parent = parent {
            parent.collectAbsolutePath(&absolutePath)
        }

        absolutePath.append(storedPath.path)
    }

    func constructStructuralRelationships() -> [[EndpointPath]: EndpointRelationship] {
        guard finishedConstruction else {
            fatalError("Constructed endpoint relationships although the tree wasn't finished parsing!")
        }

        var relationships: [[EndpointPath]: EndpointRelationship] = [:]

        for child in children {
            let operations = Operation.allCases
            child.collectRelationships(&relationships, searchList: operations, hiddenOperations: Set(minimumCapacity: operations.count / 2))
        }

        return relationships
    }

    private func constructStructuralSelfRelationship() -> EndpointRelationship {
        var relationship = EndpointRelationship(path: absolutePath)

        for endpoint in endpoints.values {
            relationship.addEndpoint(self: endpoint)
        }

        return relationship
    }

    /// This method builds all STRUCTURAL Relationships.
    /// It must be called on a subtree of the desired source node (see `constructRelationships()`).
    /// This method will recursively traverse all nodes of the subtree until it finds
    /// a `Endpoint` for every `Operation`.
    ///
    /// - Parameters:
    ///   - relationships: The array to collect all the `EndpointRelationship` instances.
    ///   - searchList: Contains all the Operations to still search for relationships.
    ///   - hiddenOperations: The DSL allows to hide certain paths from Relationship indexing.
    ///         The `Handler.hideLink(...)` modifier can be used in a way to only hide Handlers with
    ///         a certain `Operation`. This property holds the `Operation` which are hidden for the given subtree.
    ///   - respectHidden: Defines if we encountered a hideLink previously and must respect the hiddenOperations set.
    ///   - namePrefix: Prefix to prepend to the relationship name.
    ///   - relativeNamingPath: A relative path use for naming.
    ///   - nameOverride: If defined, this value will override the relationship name.
    private func collectRelationships(
        _ relationships: inout [[EndpointPath]: EndpointRelationship],
        searchList: [Operation],
        hiddenOperations: Set<Operation>,
        namePrefix: String = "",
        relativeNamingPath: [EndpointPath] = [],
        nameOverride: String? = nil
    ) {
        var prefix = namePrefix
        var override = storedPath.context.relationshipName ?? nameOverride

        var relativePath = relativeNamingPath
        relativePath.append(storedPath.path)

        if storedPath.context.isGroupEnd, let name = override {
            prefix += name
            override = nil
            relativePath = []
        }

        var hiddenOperations = hiddenOperations
        for hiddenOperation in storedPath.context.hiddenOperations {
            hiddenOperations.insert(hiddenOperation)
        }

        var searchList = searchList
        var relationship: EndpointRelationship?

        for (operation, endpoint) in endpoints {
            if let index = searchList.firstIndex(of: operation) {
                // if the operation is in our search list, we create a relationship for it and remove it from the searchList
                searchList.remove(at: index)

                if relationship == nil {
                    relationship = EndpointRelationship(path: absolutePath)
                }

                // swiftlint:disable force_unwrapping
                relationship!.addEndpoint(
                    endpoint,
                    prefix: prefix,
                    relativeNamingPath: relativePath,
                    nameOverride: override,
                    hideLink: hiddenOperations.contains(operation)
                )
            }
        }

        if let relationship = relationship {
            precondition(relationships[relationship.path] == nil,
                         "Trying to collect structural relationship \(relationship) found conflict \(String(describing: relationships[relationship.path]))")
            relationships[relationship.path] = relationship
        }

        if searchList.isEmpty {
            // if the searchList is empty we can stop searching
            return
        }

        for child in children {
            child.collectRelationships(
                &relationships,
                searchList: searchList,
                hiddenOperations: hiddenOperations,
                namePrefix: prefix,
                relativeNamingPath: relativePath,
                nameOverride: override
            )
        }
    }

    /// Used to add a `EndpointRelationship` create from a `RelationshipInstance`.
    ///
    /// - Parameters:
    ///   - reference: Reference to the `Endpoint`, use to resolve the `Operation` of the `Endpoint`.
    ///   - relationship: The `EndpointRelationship` which is to be added
    func addRelationship(at reference: EndpointReference, _ relationship: EndpointRelationship) {
        var empty: [EndpointPath] = []
        var endpoint = resolve(&empty, reference.operation)
        precondition(endpoint.absolutePath == reference.absolutePath,
                     "Called addRelationship(at:) with a seemingly unresolved `EndpointReference`")

        endpoint.addRelationship(relationship)
        endpoints[reference.operation] = endpoint
    }

    func addEndpointDestination(at reference: EndpointReference, _ destination: RelationshipDestination) {
        var empty: [EndpointPath] = []
        var endpoint = resolve(&empty, reference.operation)
        precondition(endpoint.absolutePath == reference.absolutePath,
                     "Called addEndpointDestination(at:) with a seemingly unresolved `EndpointReference`")

        endpoint.addRelationshipDestination(destination: destination, inherited: false)
        endpoints[reference.operation] = endpoint
    }

    func addRelationshipInheritance(
        at reference: EndpointReference,
        from: EndpointReference,
        for operation: Operation,
        resolvers: [AnyPathParameterResolver]
    ) {
        var empty: [EndpointPath] = []
        var endpoint = resolve(&empty, reference.operation)
        precondition(endpoint.absolutePath == reference.absolutePath,
                     "Called addRelationshipInheritance(at:from:) with a seemingly unresolved `EndpointReference`")

        let inheritance = RelationshipDestination(self: from, resolvers: resolvers)
        endpoint.addRelationshipInheritance(self: inheritance, for: operation)

        // See docs of `resolveRelationshipInheritance()`.

        endpoints[reference.operation] = endpoint
    }
}
