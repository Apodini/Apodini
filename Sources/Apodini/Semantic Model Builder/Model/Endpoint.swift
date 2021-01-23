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

    /// This property holds the `Context` instance associated with the `Endpoint`.
    /// The `Context` holds any information gathered when parsing the modeled `Handler`
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

    /// Returns the `RelationshipDestination` (with Operation equal to `operation`) for the given Endpoint
    var selfRelationship: RelationshipDestination { get }

    /// Creates a set of `RelationshipDestination` which ensures that relationship names
    /// are unique for a every `Operation`
    /// - Returns: The set of uniquely named relationship destinations.
    func relationships() -> Set<RelationshipDestination>

    /// Creates a set of `RelationshipDestination` which ensures that relationship names
    /// are unique (for all collected destination for a given `Operation`)
    /// - Parameter operation :The `Operation` of the Relationship destination to create a unique set for.
    /// - Returns: The set of uniquely named relationship destinations.
    func relationship(for operation: Operation) -> Set<RelationshipDestination>

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

    /// Internal method which is called to call the `InterfaceExporter.export(...)` method on the given `exporter`.
    ///
    /// - Parameter exporter: The `BaseInterfaceExporter` used to export the given `Endpoint`
    /// - Returns: Whatever the export method of the `InterfaceExporter` returns (which equals to type `EndpointExporterOutput`) is returned here.
    @discardableResult
    func exportEndpoint<I: BaseInterfaceExporter>(on exporter: I) -> I.EndpointExportOutput

    /// Internal method which is called once the `Tree` was finished building, meaning the DSL was parsed completely.
    mutating func finished(with relationships: [[EndpointPath]: EndpointRelationship], self structural: EndpointRelationship)

    /// This method creates a `EndpointReference` for the given `Endpoint`.
    /// The reference can be resolve using `EndpointReference.resolve()`.
    ///
    /// The reference can only be created once the `Endpoint` is fully inserted into the EndpointsTree.
    ///
    /// - Returns: `EndpointReference` to the given `Endpoint´.
    func reference() -> EndpointReference

    /// Internal method to add new relationship models to the Endpoint.
    /// - Parameter relationship: The newly added `EndpointRelationship`.
    mutating func addRelationship(_ relationship: EndpointRelationship)

    mutating func addRelationshipDestination(destination: RelationshipDestination, inherited: Bool)

    mutating func addRelationshipInheritance(self destination: RelationshipDestination, for operation: Operation)

    mutating func resolveInheritanceRelationship()
}


/// Models a single Endpoint which is identified by its PathComponents and its operation
public struct Endpoint<H: Handler>: _AnyEndpoint {
    let webservice: WebServiceModel
    var inserted = false

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

    /// See `storeRelationship(previous:store:)` for more information.
    private var storedRelationship: [EndpointRelationship] = []
    private var relationshipStorage: [[EndpointPath]: EndpointRelationship]! // swiftlint:disable:this implicitly_unwrapped_optional

    public var selfRelationship: RelationshipDestination {
        guard let destination = selfRelationship(for: operation) else {
            fatalError("Encountered inconsistency where Endpoint doesn't have a self EndpointDestination for its own Operation!")
        }

        return destination
    }
    private var structuralSelfRelationship: EndpointRelationship! // swiftlint:disable:this implicitly_unwrapped_optional
    private var inheritedSelfRelationship: EndpointRelationship?
    var inheritsRelationship: Bool {
        inheritedSelfRelationship != nil
    }

    let guards: [LazyGuard]
    let responseTransformers: [LazyAnyResponseTransformer]
    
    init(
        identifier: AnyHandlerIdentifier,
        webservice: WebServiceModel,
        handler: H,
        context: Context = Context(contextNode: ContextNode()),
        operation: Operation? = nil,
        serviceType: ServiceType = .unary,
        guards: [LazyGuard] = [],
        responseTransformers: [LazyAnyResponseTransformer] = []
    ) {
        self.identifier = identifier
        self.webservice = webservice
        self.description = String(describing: H.self)
        self.handler = handler
        self.context = context
        self.operation = operation ?? .read
        self.serviceType = serviceType
        self.handleReturnType = H.Response.Content.self
        self.guards = guards
        self.responseTransformers = responseTransformers
        self.responseType = responseTransformers.responseType(for: H.self)
        self.parameters = handler.buildParametersModel()
        self.observedObjects = handler.collectObservedObjects()
    }

    func reference() -> EndpointReference {
        guard inserted else {
            fatalError("Tried creating a `EndpointReference` of the Endpoint of \(H.self) although it wasn't fully inserted into the EndpointsTree")
        }
        return EndpointReference(webservice: webservice, absolutePath: absolutePath, operation: operation, responseType: responseType)
    }
    
    func exportEndpoint<I: BaseInterfaceExporter>(on exporter: I) -> I.EndpointExportOutput {
        exporter.export(self)
    }

    public func createConnectionContext<I: InterfaceExporter>(for exporter: I) -> ConnectionContext<I> {
        InternalConnectionContext(for: exporter, on: self)
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
        self.storedAbsolutePath = treeNode.absolutePath.scoped(on: self)
    }

    mutating func finished(with relationships: [[EndpointPath]: EndpointRelationship], self structural: EndpointRelationship) {
        self.relationshipStorage = relationships

        for relationship in relationships.values {
            storeRelationship(store: relationship)
        }

        self.structuralSelfRelationship = structural
    }

    public func relationships() -> Set<RelationshipDestination> {
        guard inserted else {
            fatalError("Tried accessing relationships for \(description) which wasn't yet present!")
        }
        return storedRelationship.unique()
    }

    public func relationship(for operation: Operation) -> Set<RelationshipDestination> {
        storedRelationship.unique(for: operation)
    }

    public func selfRelationships() -> Set<RelationshipDestination> {
        combineSelfRelationships().unique()
    }

    public func selfRelationship(for: Operation) -> RelationshipDestination? {
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

    mutating func addRelationship(_ relationship: EndpointRelationship) {
        if var existing = relationshipStorage[relationship.path] {
            // existing is probably a structural relationship, thus we override potential
            // generated destinations names with user defined one (see merge docs).
            existing.merge(with: relationship)
            relationshipStorage[relationship.path] = existing

            storeRelationship(previous: existing, store: existing)
        } else {
            relationshipStorage[relationship.path] = relationship

            storeRelationship(store: relationship)
        }
    }

    mutating func addRelationshipDestination(destination: RelationshipDestination, inherited: Bool = false) {
        if var existing = relationshipStorage[destination.destinationPath] {
            existing.add(destination: destination, inherited: inherited)
            relationshipStorage[destination.destinationPath] = existing

            storeRelationship(previous: existing, store: existing)
        } else {
            let relationship = EndpointRelationship(destination: destination)
            relationshipStorage[destination.destinationPath] = relationship

            storeRelationship(store: relationship, prepend: inherited)
        }
    }

    mutating func addRelationshipInheritance(self destination: RelationshipDestination, for operation: Operation) {
        if var inherited = inheritedSelfRelationship, inherited.path == destination.destinationPath {
            inherited.add(destination: destination)
            inheritedSelfRelationship = inherited
        } else {
            inheritedSelfRelationship = EndpointRelationship(destination: destination)
        }
    }

    /// This method is the key element of our relationship name shadowing.
    /// The `relationshipStorage` may hold duplicates (in terms of relationship names),
    /// we use the `storedRelationship` property to persist the order of insertion.
    /// As we insert automatically generated relationships first and then explicitly defines ones,
    /// name duplications will overshadow those stored first.
    ///
    /// - Parameters:
    ///   - previous: Defines if the stored Relationship replaces an existing one which needs to be removed.
    ///   - relationship: Defines the newly added EndpointRelationship
    private mutating func storeRelationship(previous: EndpointRelationship? = nil, store relationship: EndpointRelationship, prepend: Bool = false) {
        if let existing = previous, let index = storedRelationship.firstIndex(of: existing) {
            storedRelationship.remove(at: index)
        }
        if prepend {
            storedRelationship.insert(relationship, at: 0)
        } else {
            storedRelationship.append(relationship)
        }
    }

    /// Depending on "allowOverwrite" of `addRelationshipInheritance(at:from:allowOverwrite),
    /// the inherited self relationship may be overwritten
    /// (e.g. the automatically self relationship derived from type information may be
    /// overwritten by a explicitly state inheritance definition).
    /// Thus we CAN't add all the relationship from the inherited Endpoint (as we could need to reverse that operation),
    /// thus we do a two step operation:
    /// 1) Go through all relationship candidates a and set `inheritedSelfRelationship`
    /// 2) Once finished parsing candidates resolve those inheritances (this is what `resolveInheritanceRelationship()` does)
    mutating func resolveInheritanceRelationship() {
        guard let inherited = inheritedSelfRelationship else {
            return
        }

        for destination in inherited.destinations() {
            // we will use the resolvers used for for the self link for any inherited relationship
            let resolvers = destination.resolvers

            let superEndpoint = destination.reference.resolve()

            for var destination in superEndpoint.relationships() {
                // replace any resolvers for (sub relationships) with those used to resolve the inheritance
                // (e.g. based on our own properties) we can't resolve path parameters based on properties of the inheritance
                destination.replace(resolvers: resolvers)

                /// inheritance relationships are shadowed by anything already on the endpoint
                self.addRelationshipDestination(destination: destination, inherited: true)
            }
        }
    }
}

extension Endpoint: CustomDebugStringConvertible {
    public var debugDescription: String {
        String(describing: self.handler)
    }
}
