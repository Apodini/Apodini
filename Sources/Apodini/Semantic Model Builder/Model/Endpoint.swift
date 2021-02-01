//
// Created by Andi on 22.11.20.
//
import Foundation

/// Models a single Endpoint which is identified by its PathComponents and its operation
public protocol AnyEndpoint: CustomStringConvertible {
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

    /// The communication pattern that is expressed by this endpoint.
    var serviceType: ServiceType { get }

    /// Type returned by `Component.handle(...)`
    var handleReturnType: Encodable.Type { get }
    /// Response type ultimately returned by `Component.handle(...)` and possible following `ResponseTransformer`s
    var responseType: Encodable.Type { get }

    /// All `@Parameter` `RequestInjectable`s that are used inside handling `Component`
    var parameters: [AnyEndpointParameter] { get }
    /// All `@ObservedObjects` that are used inside handling `Component`
    var observedObjects: [AnyObservedObject] { get }

    var absolutePath: [EndpointPath] { get }
    var relationships: [EndpointRelationship] { get }

    /// This method can be called, to export all `EndpointParameter`s of the given `Endpoint` on the supplied `BaseInterfaceExporter`.
    /// It will call the `BaseInterfaceExporter.exporterParameter(...)` method for every parameter on this `Endpoint`.
    ///
    /// This method is particularly useful to access the fully typed version of the `EndpointParameter`.
    ///
    /// - Parameter exporter: The `BaseInterfaceExporter` to export the parameters on.
    /// - Returns: The result of the individual `BaseInterfaceExporter.exporterParameter(...)` calls.
    @discardableResult
    func exportParameters<I: BaseInterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput]

    func createConnectionContext<I: InterfaceExporter>(for exporter: I) -> AnyConnectionContext<I>

    /// This method returns the instance of a `AnyEndpointParameter` if the given `Endpoint` holds a parameter
    /// for the supplied parameter id. Otherwise nil is returned.
    ///
    /// - Parameter id: The parameter `id` to search for.
    /// - Returns: Returns the `AnyEndpointParameter` if a parameter with the given `id` exists on that `Endpoint`. Otherwise nil.
    func findParameter(for id: UUID) -> AnyEndpointParameter?
}

protocol _AnyEndpoint: AnyEndpoint {
    var guards: [LazyGuard] { get }
    var responseTransformers: [LazyAnyResponseTransformer] { get }

    /// Internal method which is called to call the `InterfaceExporter.export(...)` method on the given `exporter`.
    ///
    /// - Parameter exporter: The `BaseInterfaceExporter` used to export the given `Endpoint`
    /// - Returns: Whatever the export method of the `InterfaceExporter` returns (which equals to type `EndpointExporterOutput`) is returned here.
    @discardableResult
    func exportEndpoint<I: BaseInterfaceExporter>(on exporter: I) -> I.EndpointExportOutput

    /// Internal method which is called once the `Tree` was finished building, meaning the DSL was parsed completely.
    ///
    /// - Parameter treeNode: The tree node where this `Endpoint` is located.
    mutating func finished(at treeNode: EndpointsTreeNode)
}


/// Models a single Endpoint which is identified by its PathComponents and its operation
public struct Endpoint<H: Handler>: _AnyEndpoint {
    /// This is a reference to the node where the endpoint is located
    fileprivate var treeNode: EndpointsTreeNode! // swiftlint:disable:this implicitly_unwrapped_optional
    
    public let identifier: AnyHandlerIdentifier

    public let description: String

    public let handler: H

    public let context: Context

    public let operation: Operation

    public let serviceType: ServiceType

    public let handleReturnType: Encodable.Type
    public let responseType: Encodable.Type
    
    /// All `@Parameter` `RequestInjectable`s that are used inside handling `Component`
    public var parameters: [AnyEndpointParameter]
    /// All `@ObservedObject`s that are used inside handling `Component`
    public var observedObjects: [AnyObservedObject]

    public var absolutePath: [EndpointPath] {
        storedAbsolutePath
    }
    private var storedAbsolutePath: [EndpointPath]! // swiftlint:disable:this implicitly_unwrapped_optional

    public var relationships: [EndpointRelationship] {
        storedRelationship
    }
    private var storedRelationship: [EndpointRelationship]! // swiftlint:disable:this implicitly_unwrapped_optional

    let guards: [LazyGuard]
    let responseTransformers: [LazyAnyResponseTransformer]
    
    init(
        identifier: AnyHandlerIdentifier,
        handler: H,
        context: Context = Context(contextNode: ContextNode()),
        operation: Operation? = nil,
        serviceType: ServiceType = .unary,
        guards: [LazyGuard] = [],
        responseTransformers: [LazyAnyResponseTransformer] = []
    ) {
        self.identifier = identifier
        self.description = String(describing: H.self)
        self.handler = handler
        self.context = context
        self.operation = operation ?? .read
        self.serviceType = serviceType
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
        self.observedObjects = handler.collectObservedObjects()
    }

    fileprivate mutating func inserted(at treeNode: EndpointsTreeNode) {
        self.treeNode = treeNode
        self.storedAbsolutePath = treeNode.absolutePath.scoped(on: self)
    }

    mutating func finished(at treeNode: EndpointsTreeNode) {
        self.storedRelationship = treeNode.relationships
    }
    
    func exportEndpoint<I: BaseInterfaceExporter>(on exporter: I) -> I.EndpointExportOutput {
        exporter.export(self)
    }

    public func createConnectionContext<I: InterfaceExporter>(for exporter: I) -> AnyConnectionContext<I> {
        InternalConnectionContext(for: exporter, on: self).eraseToAnyConnectionContext()
    }

    public func findParameter(for id: UUID) -> AnyEndpointParameter? {
        parameters.first { parameter in
            parameter.id == id
        }
    }

    @discardableResult
    public func exportParameters<I: BaseInterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput] {
        parameters.exportParameters(on: exporter)
    }
}

extension Endpoint: CustomDebugStringConvertible {
    public var debugDescription: String {
        String(describing: self.handler)
    }
}

class EndpointsTreeNode {
    let path: EndpointPath
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
    
    lazy var relationships: [EndpointRelationship] = {
        guard finishedConstruction else {
            fatalError("Constructed endpoint relationships although the tree wasn't finished parsing!")
        }

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

    /// This method is called once the tree structure is built completely.
    /// At this point one can safely construct any relationships between nodes.
    func finish() {
        finishedConstruction = true
        for key in endpoints.keys {
            endpoints[key]?.finished(at: self)
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
            precondition(endpoint.treeNode == nil, "The endpoint \(endpoint.description) is already inserted at some different place")

            endpoint.inserted(at: self)
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
    
    fileprivate func collectRelationships(name: String, _ relationships: inout [EndpointRelationship]) {
        if !endpoints.isEmpty {
            var relationship = EndpointRelationship(name: name, destinationPath: absolutePath)

            if let scopingEndpoint = endpoints.getScopingEndpoint() {
                relationship.scoped(on: scopingEndpoint)
            }

            relationships.append(relationship)
            return
        }
        
        for (path, child) in nodeChildren {
            let name = name + (child.path.isParameter() ? "" : "_" + path.description)
            child.collectRelationships(name: name, &relationships)
        }
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
        path.append(parameter.toInternal().derivePathParameterModel())
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
