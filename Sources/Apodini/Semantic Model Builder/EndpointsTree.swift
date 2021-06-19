//
// Created by Andreas Bauer on 21.01.21.
//

import Foundation

class EndpointsTreeNode {
    let storedPath: StoredEndpointPath
    var endpoints: [Operation: _AnyRelationshipEndpoint] = [:]

    let parent: EndpointsTreeNode?
    private var nodeChildren: [EndpointPath: EndpointsTreeNode] = [:]
    var children: Dictionary<EndpointPath, EndpointsTreeNode>.Values {
        nodeChildren.values
    }
    /// If a EndpointsTreeNode A is a child to  a EndpointsTreeNode B and A has an `PathParameter` as its `path`
    /// B can't have any other children besides A that also have an `PathParameter` at the same location.
    /// Thus we mark `childContainsPathParameter` to true as soon as we insert a `PathParameter` as a child.
    private var childContainsPathParameter = false

    /// Describes if the `EndpointsTree` is fully built and can be considered stable
    /// (e.g. to derive information from the structure like Relationships)
    var finishedConstruction = false

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

        for child in children {
            child.finish()
        }
    }

    func addEndpoint<H: Handler>(_ endpoint: inout RelationshipEndpoint<H>, context: inout EndpointInsertionContext) {
        if context.pathEmpty {
            for parameter in endpoint[EndpointParameters.self] {
                // when the parameter is type of .path and not contained in our path, we must append it to our path
                if parameter.parameterType == .path && !context.retrievedPathContains(parameter: parameter) {
                    context.append(parameter: parameter)
                }
            }

            if !context.pathEmpty { // we added some additional parameters, see above
                return addEndpoint(&endpoint, context: &context)
            }

            // swiftlint:disable:next force_unwrapping
            precondition(endpoints[endpoint[Operation.self]] == nil, "Tried overwriting endpoint \(endpoints[endpoint[Operation.self]]!.description) with \(endpoint.description) for operation \(endpoint[Operation.self])")
            precondition(!endpoint.inserted, "The endpoint \(endpoint.description) is already inserted at some different place")

            endpoint.inserted(at: self)
            endpoints[endpoint[Operation.self]] = endpoint
        } else {
            let next = context.nextStoredPath()
            var child = nodeChildren[next.path]

            if case let .parameter(parameter) = next.path {
                // Handle inconsistency where a PathParameter contained in the path is not declared as a @Parameter.
                // This e.g. has an effect of resolvability of relationships, as the value for such a PathParameter
                // will never be retrieved and thus can't be resolved.
                precondition(endpoint.findParameter(for: parameter.id) != nil,
                             """
                             When inserting endpoint \(endpoint.description) encountered the @PathParameter \(parameter) \
                             which was not declared as a @Parameter in the Handler \(H.self).
                             Every @PathParameter of a Endpoint MUST be declared as a @Parameter in the given Handler.
                             """)
            }

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

    private func collectAbsolutePath(_ absolutePath: inout [EndpointPath]) {
        if let parent = parent {
            parent.collectAbsolutePath(&absolutePath)
        }

        absolutePath.append(storedPath.path)
    }
}

struct EndpointInsertionContext {
    private let endpoint: AnyRelationshipEndpoint
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

    init(for endpoint: AnyRelationshipEndpoint, with pathComponents: [PathComponent]) {
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
