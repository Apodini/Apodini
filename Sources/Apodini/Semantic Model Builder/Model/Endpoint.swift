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

    var absolutePath: [EndpointPath] { get }
    var relationships: [EndpointRelationship] { get }

    var guards: [LazyGuard] { get }
    var responseTransformers: [LazyAnyResponseTransformer] { get }

    func exportEndpoint<I: BaseInterfaceExporter>(on exporter: I) -> I.EndpointExportOutput

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

    var absolutePath: [EndpointPath] {
        storedAbsolutePath
    }
    private var storedAbsolutePath: [EndpointPath]! // swiftlint:disable:this implicitly_unwrapped_optional

    var relationships: [EndpointRelationship] {
        storedRelationship
    }
    private var storedRelationship: [EndpointRelationship]! // swiftlint:disable:this implicitly_unwrapped_optional

    let guards: [LazyGuard]
    let responseTransformers: [LazyAnyResponseTransformer]
    
    init(
        identifier: AnyHandlerIdentifier,
        handler: H,
        context: Context = Context(contextNode: ContextNode()),
        operation: Operation = .automatic,
        guards: [LazyGuard] = [],
        responseTransformers: [LazyAnyResponseTransformer] = []
    ) {
        self.identifier = identifier
        self.description = String(describing: handler)
        self.handler = handler
        self.context = context
        self.operation = operation
        self.handleReturnType = H.Response.Content.self
        self.guards = guards
        self.responseTransformers = responseTransformers
        self.responseType = {
            guard let lastResponseTransformer = responseTransformers.last else {
                return H.Response.Content.self
            }
            return lastResponseTransformer().transformedResponseContent
        }()
        self.parameters = handler.buildParametersModel()
    }

    fileprivate mutating func onInserted(at treeNode: EndpointsTreeNode) {
        self.treeNode = treeNode
        self.storedAbsolutePath = treeNode.absolutePath.scoped(on: self)
        self.storedRelationship = treeNode.relationships.scoped(on: self)
    }
    
    func exportEndpoint<I: BaseInterfaceExporter>(on exporter: I) -> I.EndpointExportOutput {
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
    let path: EndpointPath
    var endpoints: [Operation: AnyEndpoint] = [:]
    
    let parent: EndpointsTreeNode?
    private var nodeChildren: [EndpointPath: EndpointsTreeNode] = [:]
    var children: Dictionary<EndpointPath, EndpointsTreeNode>.Values {
        nodeChildren.values
    }
    /// If a EndpointsTreeNode A is a child to  a EndpointsTreeNode B and A has an `PathParameter` as its `path`
    /// B can't have any other children besides A that also have an `PathParameter` at the same location.
    /// Thus we mark `childContainsPathParameter` to true as soon as we insert a `PathParameter` as a child.
    private var childContainsPathParameter = false
    
    lazy var absolutePath: [EndpointPath] = {
        var absolutePath: [EndpointPath] = []
        collectAbsolutePath(&absolutePath)
        return absolutePath
    }()
    
    lazy var relationships: [EndpointRelationship] = {
        var relationships: [EndpointRelationship] = []
        
        for (path, child) in nodeChildren {
            child.collectRelationships(name: path.description, &relationships)
        }
        
        return relationships
    }()
    
    init(path: EndpointPath, parent: EndpointsTreeNode? = nil) {
        self.path = path
        self.parent = parent
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
            precondition(endpoint.treeNode == nil, "The endpoint \(endpoint.description) is already inserted at some different place")

            endpoint.onInserted(at: self)
            endpoints[endpoint.operation] = endpoint
        } else {
            let next = context.nextPath()
            var child = nodeChildren[next]

            if child == nil {
                // as we create a new child node we need to check if there are colliding path parameters
                switch next {
                case .parameter:
                    if childContainsPathParameter { // there are already some children with a path parameter on this level
                        fatalError("When inserting endpoint \(endpoint.description) we encountered a path parameter collision on level n-\(context.pathCount): "
                            + "You can't have multiple path parameters on the same level!")
                    } else {
                        childContainsPathParameter = true
                    }
                default:
                    break
                }

                child = EndpointsTreeNode(path: next, parent: self)
                nodeChildren[next] = child
            }

            // swiftlint:disable:next force_unwrapping
            child!.addEndpoint(&endpoint, context: &context)
        }
    }
    
    private func collectAbsolutePath(_ absolutePath: inout [EndpointPath]) {
        if let parent = parent {
            parent.collectAbsolutePath(&absolutePath)
        }

        absolutePath.append(path)
    }
    
    func relativePath(from node: EndpointsTreeNode) -> [EndpointPath] {
        var relativePath: [EndpointPath] = []
        collectRelativePath(&relativePath, from: node)
        return relativePath
    }
    
    private func collectRelativePath(_ relativePath: inout [EndpointPath], from node: EndpointsTreeNode) {
        if node === self {
            return
        }
        if let parent = parent {
            parent.collectRelativePath(&relativePath, from: node)
        }

        relativePath.append(path)
    }
    
    fileprivate func collectRelationships(name: String, _ relationships: inout [EndpointRelationship]) {
        if !endpoints.isEmpty {
            relationships.append(EndpointRelationship(name: name, destinationPath: absolutePath))
            return
        }
        
        for (path, child) in nodeChildren {
            // as Parameter is currently inserted into the path (which will change)
            // checking against RequestInjectable is a lazy check to determine if this is a path parameter
            // or just a regular path component. To be adapted.
            let name = path.description + (child.path is RequestInjectable ? "" : "_" + path.description)
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
        
        for child in nodeChildren.values {
            child.printTree(indent: indent + 1)
        }
        
        print(indentString + "}")
    }
}

struct EndpointInsertionContext {
    private var path: [EndpointPath]
    /// This array holds all UUIDs of Parameters which were already retrieved from the path array above.
    /// This is used to decide if we need to add a PathParameter which has a definition in the Handler
    /// but not a dedicated definition contained in the PathComponents
    private var retrievedParameters: [UUID] = []

    var pathEmpty: Bool {
        path.isEmpty
    }
    var pathCount: Int {
        path.count
    }

    init(pathComponents: [PathComponent]) {
        self.path = pathComponents.buildPathModel().path
    }

    func retrievedPathContains(parameter: AnyEndpointParameter) -> Bool {
        retrievedParameters.contains(parameter.id)
    }

    mutating func append(parameter: AnyEndpointParameter) {
        path.append(parameter.derivePathParameterModel())
    }

    mutating func assertRootPath() {
        let next = nextPath()
        switch next {
        case .root:
            break
        default:
            fatalError("Endpoint Path Model didn't start with a .root path!")
        }
    }

    mutating func nextPath() -> EndpointPath {
        let next = path.removeFirst()

        switch next {
        case let .parameter(parameter):
            retrievedParameters.append(parameter.id)
        default:
            break
        }

        return next
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
