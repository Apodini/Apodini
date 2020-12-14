//
// Created by Andi on 22.11.20.
//

import Vapor


/// This struct is used to model the RootPath for the root of the endpoints tree
struct RootPath: _PathComponent {
    var description: String {
        ""
    }

    func append<P>(to pathBuilder: inout P) where P: PathBuilder {
        fatalError("RootPath instances should not be appended to anything")
    }
}

struct EndpointRelationship { // ... to be replaced by a proper Relationship model
    var destinationPath: [_PathComponent]
}

/// Models a single Endpoint which is identified by its PathComponents and its operation
struct Endpoint {
    /// This is a reference to the node where the endpoint is located
    // swiftlint:disable:next implicitly_unwrapped_optional
    fileprivate var treeNode: EndpointsTreeNode!

    /// Description of the associated component, currently included for debug purposes
    let description: String

    /// The reference to the Context instance should be removed in the "final" state of the semantic model.
    /// I chose to include it for now as it makes the process of moving to a central semantic model easier,
    /// as implementing exporters can for now extract their needed information from the context on their own
    /// and can then pull in their requirements into the Semantic Model.
    let context: Context

    let operation: Operation

    fileprivate var requestHandlerBuilder: RequestHandlerBuilder
    /// Type returned by `handle()`
    let handleReturnType: Encodable.Type
    /// Response type ultimately returned by `handle()` and possible following `ResponseTransformer`s
    var responseType: Encodable.Type
    
    /// All `@Parameter` `RequestInjectable`s that are used inside handling `Component`
    var parameters: [EndpointParameter]

    var absolutePath: [_PathComponent] {
        treeNode.absolutePath
    }
    var relationships: [EndpointRelationship] {
        treeNode.relationships
    }


    init(description: String, context: Context, operation: Operation,
         requestHandlerBuilder: @escaping RequestHandlerBuilder,
         handleReturnType: Encodable.Type, responseType: Encodable.Type, parameters: [EndpointParameter]) {
        self.description = description
        self.context = context
        self.operation = operation
        self.requestHandlerBuilder = requestHandlerBuilder
        self.handleReturnType = handleReturnType
        self.responseType = responseType
        self.parameters = parameters
    }

    func createRequestHandler(for exporter: InterfaceExporter) -> (Request) -> EventLoopFuture<Encodable> {
        requestHandlerBuilder(exporter)
    }

}

class EndpointsTreeNode {
    let path: _PathComponent
    var endpoints: [Operation: Endpoint] = [:]

    let parent: EndpointsTreeNode?
    private var nodeChildren: [String: EndpointsTreeNode] = [:]
    var children: Dictionary<String, EndpointsTreeNode>.Values {
        nodeChildren.values
    }
    /// If a EndpointsTreeNode A is a child to  a EndpointsTreeNode B and A has an `PathParameter` as its `path`
    /// B can't have any other children besides A that also have an `PathParameter` at the same location.
    /// Thus we mark `childContainsPathParameter` to true as soon as we insert a `PathParameter` as a child.
    private var childContainsPathParameter = false

    lazy var absolutePath: [_PathComponent] = {
        var absolutePath: [_PathComponent] = []
        collectAbsolutePath(&absolutePath)
        return absolutePath
    }()

    lazy var relationships: [EndpointRelationship] = {
        var relationships: [EndpointRelationship] = []

        for child in children {
            child.collectRelationships(&relationships)
        }

        return relationships
    }()

    init(path: _PathComponent, parent: EndpointsTreeNode? = nil) {
        self.path = path
        self.parent = parent
    }

    func addEndpoint(_ endpoint: inout Endpoint, at paths: [PathComponent]) {
        if paths.isEmpty {
            // swiftlint:disable:next force_unwrapping
            precondition(endpoints[endpoint.operation] == nil, "Tried overwriting endpoint \(endpoints[endpoint.operation]!.description) with \(endpoint.description) for operation \(endpoint.operation)")
            precondition(endpoint.treeNode == nil, "The endpoint \(endpoint.description) is already inserted at some different place")
            endpoint.treeNode = self
            endpoints[endpoint.operation] = endpoint
        } else {
            var pathComponents = paths
            if let first = pathComponents.removeFirst() as? _PathComponent {
                var child = nodeChildren[first.description]
                if child == nil {
                    // as we create a new child node we need to check if there are colliding path parameters
                    if let result = PathComponentAnalyzer.analyzePathComponentForParameter(first) {
                        if result.parameterMode != .path {
                            fatalError("Parameter can only be used as path component when setting .http() parameter option to .path!")
                        }

                        if childContainsPathParameter { // there are already some children with a path parameter on this level
                            fatalError("When inserting endpoint \(endpoint.description) we encountered a path parameter collision on level n-\(pathComponents.count): "
                                    + "You can't have multiple path parameters on the same level!")
                        } else {
                            childContainsPathParameter = true
                        }
                    }

                    child = EndpointsTreeNode(path: first, parent: self)
                    nodeChildren[first.description] = child
                }

                // swiftlint:disable:next force_unwrapping
                child!.addEndpoint(&endpoint, at: pathComponents)
            } else {
                fatalError("Encountered PathComponent which isn't a _PathComponent!")
            }
        }
    }

    private func collectAbsolutePath(_ absolutePath: inout [_PathComponent]) {
        guard let parent = parent else {
            return
        }

        parent.collectAbsolutePath(&absolutePath)
        absolutePath.append(path)
    }

    func relativePath(to node: EndpointsTreeNode) -> [_PathComponent] {
        var relativePath: [_PathComponent] = []
        collectRelativePath(&relativePath, to: node)
        return relativePath
    }

    private func collectRelativePath(_ relativePath: inout [_PathComponent], to node: EndpointsTreeNode) {
        if node === self {
            return
        }
        guard let parent = parent else {
            return
        }

        parent.collectRelativePath(&relativePath, to: node)
        relativePath.append(path)
    }

    fileprivate func collectRelationships(_ relationships: inout [EndpointRelationship]) {
        if endpoints.count > 0 {
            relationships.append(EndpointRelationship(destinationPath: absolutePath))
            return
        }

        for child in children {
            child.collectRelationships(&relationships)
        }
    }

    /// This method prints the tree structure to stdout. Added for debugging purposes.
    func printTree(indent: Int = 0) {
        let indentString = String(repeating: "  ", count: indent)

        print(indentString + path.description + "/ {")

        for (operation, endpoint) in endpoints {
            print(indentString + "  - \(operation): " + endpoint.description)
        }

        for child in nodeChildren {
            child.value.printTree(indent: indent + 1)
        }

        print(indentString + "}")
    }
}
