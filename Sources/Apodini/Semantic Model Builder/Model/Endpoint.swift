//
// Created by Andreas Bauer on 22.11.20.
//
import Foundation

/// Models a single Endpoint which is identified by its PathComponents and its operation
public protocol AnyEndpoint: Blackboard, CustomStringConvertible {
    /// All `@Parameter` `RequestInjectable`s that are used inside handling `Component`
    var parameters: [AnyEndpointParameter] { get }

    var absolutePath: [EndpointPath] { get }

    /// Returns the `RelationshipDestination` (with Operation equal to `operation`) for the given Endpoint
    var selfRelationship: RelationshipDestination { get }

    /// Creates a set of `RelationshipDestination` which ensures that relationship names
    /// are unique for a every `Operation`
    /// - Returns: The set of uniquely named relationship destinations.
    func relationships() -> Set<RelationshipDestination>

    /// Creates a set of `RelationshipDestination` which ensures that relationship names
    /// are unique (for all collected destination for a given `Operation`)
    /// - Parameter operation: The `Operation` of the Relationship destination to create a unique set for.
    /// - Returns: The set of uniquely named relationship destinations.
    func relationships(for operation: Operation) -> Set<RelationshipDestination>

    /// Returns the special "self" Relationship for all `Operation`s.
    func selfRelationships() -> Set<RelationshipDestination>

    /// Returns the special "self" Relationship for a given `Operation`
    /// - Parameter for: The `Operation` for the desired destination.
    func selfRelationship(for: Operation) -> RelationshipDestination?

    /// This method can be called, to export all `EndpointParameter`s of the given `Endpoint` on the supplied `BaseInterfaceExporter`.
    /// It will call the `BaseInterfaceExporter.exporterParameter(...)` method for every parameter on this `Endpoint`.
    ///
    /// This method is particularly useful to access the fully typed version of the `EndpointParameter`.
    ///
    /// - Parameter exporter: The `BaseInterfaceExporter` to export the parameters on.
    /// - Returns: The result of the individual `BaseInterfaceExporter.exporterParameter(...)` calls.
    @discardableResult
    func exportParameters<I: BaseInterfaceExporter>(on exporter: I) -> [I.ParameterExportOutput]

    func createConnectionContext<I: InterfaceExporter>(for exporter: I) -> ConnectionContext<I>

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

    /// This property holds a `EndpointReference` for the given `Endpoint`.
    /// The reference can be resolve using `EndpointReference.resolve()`.
    ///
    /// The reference can only be accessed once the `Endpoint` is fully inserted into the EndpointsTree.
    ///
    /// - Returns: `EndpointReference` to the given `Endpoint´.
    var reference: EndpointReference { get }

    /// Internal method which is called to call the `InterfaceExporter.export(...)` method on the given `exporter`.
    ///
    /// - Parameter exporter: The `BaseInterfaceExporter` used to export the given `Endpoint`
    /// - Returns: Whatever the export method of the `InterfaceExporter` returns (which equals to type `EndpointExporterOutput`) is returned here.
    @discardableResult
    func exportEndpoint<I: BaseInterfaceExporter>(on exporter: I) -> I.EndpointExportOutput

    /// Internal method to initialize the endpoint with built relationships.
    /// - Parameter result: The `RelationshipBuilderResult` handing over all relationships for the endpoint.
    mutating func initRelationships(with result: RelationshipBuilderResult)
}


/// Models a single Endpoint which is identified by its PathComponents and its operation
public struct Endpoint<H: Handler>: _AnyEndpoint {
    private let blackboard: Blackboard
    
    var inserted = false

    var reference: EndpointReference {
        guard let endpointReference = storedReference else {
            fatalError("Tried accessing the `EndpointReference` of the Endpoint of \(H.self) although it wasn't fully inserted into the EndpointsTree")
        }
        return endpointReference
    }
    private var storedReference: EndpointReference?

    public let handler: H
    
    /// All `@Parameter` `RequestInjectable`s that are used inside handling `Component`
    public var parameters: [AnyEndpointParameter] {
        self[EndpointParameters.self]
    }

    public var absolutePath: [EndpointPath] {
        storedAbsolutePath
    }
    private var storedAbsolutePath: [EndpointPath]! // swiftlint:disable:this implicitly_unwrapped_optional

    private var storedRelationship: [EndpointRelationship] = []

    public var selfRelationship: RelationshipDestination {
        guard let destination = selfRelationship(for: self[Operation.self]) else {
            fatalError("Encountered inconsistency where Endpoint doesn't have a self EndpointDestination for its own Operation!")
        }

        return destination
    }
    private var structuralSelfRelationship: EndpointRelationship! // swiftlint:disable:this implicitly_unwrapped_optional
    private var inheritedSelfRelationship: EndpointRelationship?
    public var inheritsRelationship: Bool {
        inheritedSelfRelationship != nil
    }

    let guards: [LazyGuard]
    let responseTransformers: [LazyAnyResponseTransformer]
    
    init(
        handler: H,
        blackboard: Blackboard,
        guards: [LazyGuard] = [],
        responseTransformers: [LazyAnyResponseTransformer] = []
    ) {
        self.handler = handler
        self.guards = guards
        self.responseTransformers = responseTransformers
        self.blackboard = blackboard
    }
    
    public subscript<S>(_ type: S.Type) -> S where S: KnowledgeSource {
        get {
            self.blackboard[type]
        }
        nonmutating set {
            self.blackboard[type] = newValue
        }
    }
    
    public func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource {
        try self.blackboard.request(type)
    }
    
    func exportEndpoint<I: BaseInterfaceExporter>(on exporter: I) -> I.EndpointExportOutput {
        exporter.export(self)
    }

    public func createConnectionContext<I: InterfaceExporter>(for exporter: I) -> ConnectionContext<I> {
        EndpointSpecificConnectionContext(for: exporter, on: self)
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

    mutating func inserted(at treeNode: EndpointsTreeNode) {
        inserted = true
        storedAbsolutePath = treeNode.absolutePath.scoped(on: self)
        storedReference = EndpointReference(on: treeNode, off: self)
    }

    mutating func initRelationships(with result: RelationshipBuilderResult) {
        self.structuralSelfRelationship = result.structuralSelfRelationship
        self.inheritedSelfRelationship = result.inheritedSelfRelationship
        self.storedRelationship = result.relationships
    }

    public func relationships() -> Set<RelationshipDestination> {
        guard inserted else {
            fatalError("Tried accessing relationships for \(description) which wasn't yet present!")
        }
        return storedRelationship.unique()
    }

    public func relationships(for operation: Operation) -> Set<RelationshipDestination> {
        storedRelationship.unique(for: operation)
    }

    public func selfRelationships() -> Set<RelationshipDestination> {
        combineSelfRelationships().unique()
    }

    public func selfRelationship(for operation: Operation) -> RelationshipDestination? {
        // the unique set will only have one entry (maybe even none)
        combineSelfRelationships().unique(for: operation).first
    }

    /// Combines `EndpointRelationship` instance representing the self relationship.
    /// - Returns: Array of `EndpointRelationships`. Index 0 will always hold the default
    ///     `structuralSelfRelationship` which is always defined for an `Endpoint`
    ///     (as soon as the `Endpoint` is fully inserted into the tree).
    ///     If the `Endpoint` has an inherited self relationship index 1 will hold that instance.
    private func combineSelfRelationships() -> [EndpointRelationship] {
        var relationships: [EndpointRelationship] = [structuralSelfRelationship]
        if let inherits = inheritedSelfRelationship {
            // appending the inheritance will result in it overriding our structural defaults
            relationships.append(inherits)
        }
        return relationships
    }
}

extension Endpoint: CustomDebugStringConvertible {
    public var debugDescription: String {
        String(describing: self.handler)
    }
}

extension Endpoint: CustomStringConvertible {
    public var description: String {
        self[HandlerDescription.self]
    }
}
