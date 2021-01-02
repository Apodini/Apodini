//
// Created by Andi on 22.11.20.
//
import Foundation

/// Models a single Endpoint which is identified by its PathComponents and its operation
protocol AnyEndpoint: CustomStringConvertible {
    /// An identifier which uniquely identifies this endpoint (via its handler)
    /// across multiple compilations and executions of the web service.
    var identifier: AnyHandlerIdentifier { get }
    
    /// Description of the `Handler` this endpoint was generated for
    var description: String { get }

    /// The reference to the Context instance should be removed in the "final" state of the semantic model.
    /// I chose to include it for now as it makes the process of moving to a central semantic model easier,
    /// as implementing exporters can for now extract their needed information from the context on their own
    /// and can then pull in their requirements into the Semantic Model.
    var context: Context { get }

    var operation: Operation { get }

    /// Type returned by `Component.handle(...)`
    var handleReturnType: Encodable.Type { get }
    /// Response type ultimately returned by `Component.handle(...)` and possible following `ResponseTransformer`s
    var responseType: Encodable.Type { get }

    /// All `@Parameter` `RequestInjectable`s that are used inside handling `Component`
    var parameters: [AnyEndpointParameter] { get }

    var absolutePath: [_PathComponent] { get }
    var relationships: [EndpointRelationship] { get }

    var guards: [LazyGuard] { get }
    var responseTransformers: [() -> (AnyResponseTransformer)] { get }

    func exportEndpoint<I: InterfaceExporter>(on exporter: I) -> I.EndpointExportOutput

    func createConnectionContext<I: InterfaceExporter>(for exporter: I) -> AnyConnectionContext<I>
    
    func findParameter(for id: UUID) -> AnyEndpointParameter?
    
    func exportParameters<I: InterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput]
}


/// Models a single Endpoint which is identified by its PathComponents and its operation
struct Endpoint<H: Handler>: AnyEndpoint {
    /// This is a reference to the node where the endpoint is located
    fileprivate var treeNode: EndpointsTreeNode! // swiftlint:disable:this implicitly_unwrapped_optional
    
    let identifier: AnyHandlerIdentifier

    let description: String

    let handler: H
    
    let context: Context
    
    let operation: Operation
    
    let handleReturnType: Encodable.Type
    let responseType: Encodable.Type
    
    /// All `@Parameter` `RequestInjectable`s that are used inside handling `Component`
    var parameters: [AnyEndpointParameter]
    
    var absolutePath: [_PathComponent] {
        treeNode.absolutePath
    }
    var relationships: [EndpointRelationship] {
        treeNode.relationships
    }

    let guards: [LazyGuard]
    let responseTransformers: [() -> (AnyResponseTransformer)]
    
    
    init(
        identifier: AnyHandlerIdentifier,
        handler: H,
        context: Context = Context(contextNode: ContextNode()),
        operation: Operation = .automatic,
        guards: [LazyGuard] = [],
        responseTransformers: [() -> (AnyResponseTransformer)] = [],
        parameters: [AnyEndpointParameter] = []
    ) {
        self.identifier = identifier
        self.description = String(describing: handler)
        self.handler = handler
        self.context = context
        self.operation = operation
        self.handleReturnType = H.Response.self
        self.guards = guards
        self.responseTransformers = responseTransformers
        self.responseType = {
            guard let lastResponseTransformer = responseTransformers.last else {
                return H.Response.self
            }
            return lastResponseTransformer().transformedResponseType
        }()
        self.parameters = parameters
    }
    
    func exportEndpoint<I: InterfaceExporter>(on exporter: I) -> I.EndpointExportOutput {
        exporter.export(self)
    }
    
    func createConnectionContext<I: InterfaceExporter>(for exporter: I) -> AnyConnectionContext<I> {
        InternalConnectionContext(for: exporter, on: self).eraseToAnyConnectionContext()
    }

    func findParameter(for id: UUID) -> AnyEndpointParameter? {
        parameters.first { parameter in
            parameter.id == id
        }
    }

    func exportParameters<I: InterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput] {
        parameters.exportParameters(on: exporter)
    }
}


class EndpointsTreeNode {
    let path: _PathComponent
    var endpoints: [Operation: AnyEndpoint] = [:]
    
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
        
        for (name, child) in nodeChildren {
            child.collectRelationships(name: name, &relationships)
        }
        
        return relationships
    }()
    
    init(path: _PathComponent, parent: EndpointsTreeNode? = nil) {
        self.path = path
        self.parent = parent
    }
    
    func addEndpoint<H: Handler>(_ endpoint: inout Endpoint<H>, at paths: [PathComponent]) {
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
    
    fileprivate func collectRelationships(name: String, _ relationships: inout [EndpointRelationship]) {
        if !endpoints.isEmpty {
            relationships.append(EndpointRelationship(name: name, destinationPath: absolutePath))
            return
        }
        
        for (childName, child) in nodeChildren {
            // as Parameter is currently inserted into the path (which will change)
            // checking against RequestInjectable is a lazy check to determine if this is a path parameter
            // or just a regular path component. To be adapted.
            let name = name + (child.path is RequestInjectable ? "" : "_" + childName)
            child.collectRelationships(name: name, &relationships)
        }
    }
    
    /// This method prints the tree structure to stdout. Added for debugging purposes.
    func printTree(indent: Int = 0) {
        let indentString = String(repeating: "  ", count: indent)
        
        print(indentString + path.description + "/ {")
        
        for (operation, endpoint) in endpoints {
            print("\(indentString)  - \(operation): \(endpoint.description) [\(endpoint.identifier.rawValue)]")
        }
        
        for child in nodeChildren {
            child.value.printTree(indent: indent + 1)
        }
        
        print(indentString + "}")
    }
}


/// Helper type which acts as a Hashable wrapper around `AnyEndpoint` 
private struct AnyHashableEndpoint: Hashable, Equatable {
    let endpoint: AnyEndpoint
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(endpoint.identifier)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.endpoint.identifier == rhs.endpoint.identifier
    }
}


extension EndpointsTreeNode {
    func collectAllEndpoints() -> [AnyEndpoint] {
        if let parent = parent {
            return parent.collectAllEndpoints()
        }
        var endpoints = Set<AnyHashableEndpoint>()
        collectAllEndpoints(into: &endpoints)
        return endpoints.map(\.endpoint)
    }
    
    private func collectAllEndpoints(into endpointsSet: inout Set<AnyHashableEndpoint>) {
        endpointsSet.formUnion(self.endpoints.values.map { AnyHashableEndpoint(endpoint: $0) })
        for child in children {
            child.collectAllEndpoints(into: &endpointsSet)
        }
    }
}
