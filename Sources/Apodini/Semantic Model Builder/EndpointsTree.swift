//
// Created by Andi on 22.11.20.
//

import Vapor
import Runtime

/// This struct is used to model the RootPath for the root of the endpoints tree
struct RootPath: _PathComponent {
    var description: String {
        ""
    }

    func append<P>(to pathBuilder: inout P) where P: PathBuilder {
        fatalError("RootPath instances should not be appended to anything")
    }
}

/// Models a single Endpoint which is identified by its PathComponents and its operation
struct Endpoint {
    /// This is a reference to the node where the endpoint is located
    // swiftlint:disable:next implicitly_unwrapped_optional
    var treeNode: EndpointsTreeNode!

    /// Description of the associated component, currently included for debug purposes
    let description: String

    /// The reference to the Context instance should be removed in the "final" state of the semantic model.
    /// I chose to include it for now as it makes the process of moving to a central semantic model easier,
    /// as implementing exporters can for now extract their needed information from the context on their own
    /// and can then pull in their requirements into the Semantic Model.
    let context: Context

    let operation: Operation

    let guards: [LazyGuard]
    let requestInjectables: [String: RequestInjectable]
    let handleMethod: () -> ResponseEncodable
    let responseTransformers: [() -> (AnyResponseTransformer)]
    
    /// Type returned by `handle()`
    let handleReturnType: ResponseEncodable.Type
    
    /// Response type ultimately returned by `handle()` and possible following `ResponseTransformer`s
    lazy var responseType: ResponseEncodable.Type = {
        guard let lastResponseTransformer = self.responseTransformers.last else {
            return self.handleReturnType
        }
        return lastResponseTransformer().transformedResponseType
    }()
    
    /// All `@Parameter` `RequestInjectable`s that are used inside handling `Component`
    lazy var parameters: [EndpointParameter] = EndpointParameter.create(from: requestInjectables)

    lazy var pathComponents: [_PathComponent] = {
        treeNode.pathComponents
    }()
}

class EndpointsTreeNode {
    let path: _PathComponent
    lazy var pathComponents: [_PathComponent] = {
        var paths: [_PathComponent] = []
        collectPathComponents(pathComponents: &paths)
        return paths
    }()

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
                    // swiftlint:disable:next todo
                    // TODO is there a better way to check for type Parameter instead of string comparison?
                    if let info = try? typeInfo(of: type(of: first)), info.mangledName == "Parameter" {
                        let mirror = Mirror(reflecting: first)

                        // swiftlint:disable:next force_cast
                        let options = mirror.children.first { $0.label == "options" }!.value as! PropertyOptionSet<ParameterOptionNameSpace>
                        if options.option(for: PropertyOptionKey.http) != .path {
                            fatalError("Parameter can only be used as path component when setting .http to .path!")
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

    private func collectPathComponents(pathComponents: inout [_PathComponent]) {
        if path is RootPath {
            return
        }

        pathComponents.insert(path, at: 0)
        parent?.collectPathComponents(pathComponents: &pathComponents)
    }

    /// This method prints the tree structure to stdout. Added for debugging purposes.
    func printTree(indent: Int = 0) {
        let indentString = String(repeating: "  ", count: indent)

        print(indentString + path.description + "/ {")

        for (operation, endpoint) in endpoints {
            print(indentString + "  -\(operation): " + endpoint.description)
        }

        for child in nodeChildren {
            child.value.printTree(indent: indent + 1)
        }

        print(indentString + "}")
    }
}
