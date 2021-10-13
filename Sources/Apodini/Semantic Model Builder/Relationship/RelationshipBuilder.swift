//
// Created by Andreas Bauer on 19.01.21.
//

import Foundation
import Logging

/// Defines the outcome of the Relationship building process for a given `Endpoint`.
struct RelationshipBuilderResult {
    /// Defines the always present "self" Relationship pointing to the `Endpoint` itself.
    let structuralSelfRelationship: EndpointRelationship
    /// If the `Endpoint` inherits from any other `Endpoint`, this holds the
    /// updated "self" relationship pointing to the new self.
    /// They should shadow any destinations in `structuralSelfRelationship`, but as
    /// they are located under different paths, they can't be combined into one `EndpointRelationship`.
    let inheritedSelfRelationship: EndpointRelationship?

    /// Contains all `EndpointRelationship`s for the `Endpoint` order as
    /// described for our name shadowing logic (see `BuildingEndpoint`).
    /// Thus might contain name collisions.
    /// `[EndpointRelationship].unique(...)` might be used to get a unique set.
    let relationships: [EndpointRelationship]
}

/// The `RelationshipInstanceBuilder` is used to collect `Relationship` instances
/// manually defined by the user, to build `EndpointRelationship`s out of it.
class RelationshipBuilder {
    private let logger: Logger

    private var endpoints: [EndpointReference: BuildingEndpoint] = [:]
    /// Collects any endpoint reference which needs resolving of inherited relationships afterwards.
    private var needsInheritanceResolving: [EndpointReference] = []

    private var collectedRelationshipInstances: [UUID: RelationshipInstance] = [:]
    private(set) var collectedRelationshipCandidates: [PartialRelationshipSourceCandidate] = []

    init(logger: Logger) {
        self.logger = logger
    }

    /// Called for a newly `Endpoint` to be indexed by the RelationshipBuilder.
    /// This must be called for **every** Endpoint, in order to build structural Relationships.
    /// - Parameters:
    ///   - endpoint: The `Endpoint` which is to be collected
    ///   - candidates: Array of `PartialRelationshipSourceCandidate` which may be defined for the `Endpoint`.
    ///   - sources: Array of `Relationship` instance this `Endpoint` is declared a source of.
    ///   - destinations: Array of `Relationship` instance this `Endpoint` is declared a destination of.
    func collect<H: Handler>(
        endpoint: RelationshipEndpoint<H>,
        candidates: [PartialRelationshipSourceCandidate],
        sources: [Relationship],
        destinations: [Relationship]
    ) {
        precondition(endpoints[endpoint.reference] == nil, "Collected the same endpoint \(endpoint.reference) twice!")
        endpoints[endpoint.reference] = BuildingEndpoint(for: endpoint.reference)

        collectRelationshipCandidates(for: endpoint, candidates)
        collectSources(for: endpoint, sources)
        collectDestinations(for: endpoint, destinations)
    }

    private func collectRelationshipCandidates<H: Handler>(
        for endpoint: RelationshipEndpoint<H>,
        _ partialCandidates: [PartialRelationshipSourceCandidate]) {
        collectedRelationshipCandidates.append(contentsOf: partialCandidates.linked(to: endpoint))
    }

    private func collectSources<H: Handler>(for endpoint: RelationshipEndpoint<H>, _ relationships: [Relationship]) {
        for source in relationships {
            modifyRelationshipInstance(for: source) { instance in
                instance.addSource(endpoint)
            }
        }
    }

    private func collectDestinations<H: Handler>(for endpoint: RelationshipEndpoint<H>, _ relationships: [Relationship]) {
        for destination in relationships {
            modifyRelationshipInstance(for: destination) { instance in
                instance.addDestination(endpoint)
            }
        }
    }

    private func modifyRelationshipInstance(for relationship: Relationship, operation: (inout RelationshipInstance) -> Void) {
        var instance = collectedRelationshipInstances[relationship.id, default: RelationshipInstance(name: relationship.name)]
        precondition(instance.name == relationship.name, "Encountered Relationship with same id but different names (existent '\(instance.name)' didn't match '\(relationship.name)')")

        operation(&instance)

        collectedRelationshipInstances[relationship.id] = instance
    }

    /// Called to resolve `RelationshipInstances` we collected while parsing `Endpoints`.
    private func resolveInstances() {
        for instance in collectedRelationshipInstances.values {
            let built = instance.build()

            for (source, relationship) in built {
                addRelationshipInstance(at: source, relationship)
            }
        }
    }

    func buildAll() {
        // as last resolve step, we still have to call to resolve `RelationshipInstances`
        resolveInstances()

        logger.debug("Resolving inherited relationships in order [\(needsInheritanceResolving.map { $0.description }.joined(separator: ", "))]")
        for reference in needsInheritanceResolving {
            guard let endpoint = endpoints[reference] else {
                fatalError("The `BuildingEndpoint` \(reference) went missing while trying to resolve inherited relationships!")
            }

            resolveInheritanceRelationship(endpoint: endpoint)
        }

        for collected in endpoints.values {
            collected.build()
        }
    }

    func addRelationshipInheritance(at reference: EndpointReference, from: EndpointReference, resolvers: [AnyPathParameterResolver]) {
        endpoints[reference, default: BuildingEndpoint(for: reference)]
            .addInheritance(from: from, with: resolvers)

        // See docs of `RelationshipBuilder.resolveInheritanceRelationship()`.
        needsInheritanceResolving.append(reference)
    }

    func addDestinationFromExplicitTyping(at reference: EndpointReference,
                                          name: String,
                                          destination: EndpointReference,
                                          with resolvers: [AnyPathParameterResolver]) {
        endpoints[reference, default: BuildingEndpoint(for: reference)]
            .addDestinationFromExplicitTyping(name: name, destination: destination, with: resolvers)
    }

    /// To be called for `EndpointRelationship` which are created from `EndpointInstances` only!
    private func addRelationshipInstance(at reference: EndpointReference, _ relationship: EndpointRelationship) {
        endpoints[reference, default: BuildingEndpoint(for: reference)]
            .addRelationshipInstance(relationship)
    }

    func selfRelationshipResolvers(for reference: EndpointReference) -> [AnyPathParameterResolver] {
        guard let endpoint = endpoints[reference] else {
            fatalError("Tried accessing selfRelationship resolvers but didn't have an endpoint for \(reference)!")
        }
        return endpoint.selfRelationshipResolvers()
    }

    /// This method resolves inherited relationships for the given `BuildingEndpoint`.
    /// There are two reasons why we can't immediately execute this step when parsing a inheritance definition.
    /// - There might be a explicit `RelationshipInheritance` definition which overwrites a automatically generated one
    ///     which would require us to undo the resolve operation, if we would do it immediately.
    /// - The inheritance resolve step is required to be executed before parsing .link or .reference candidates.
    ///   In order to properly inherited those relationships generated from the Relationship DSL, we must delay this step.
    /// - Parameter endpoint: The `BuildingEndpoint` to resolve relationships for.
    private func resolveInheritanceRelationship(endpoint: BuildingEndpoint) {
        guard let inherited = endpoint.inheritedSelfRelationship else {
            return
        }

        for destination in inherited.destinations {
            guard let superEndpoint = endpoints[destination.reference] else {
                fatalError("""
                           Indexed a inheritance for endpoint \(endpoint.reference) for which the  destination \
                           \(destination.reference) couldn't be found in our collected endpoints.
                           """)
            }

            // we will use the resolvers used for for the self link for any inherited relationship
            let resolvers = destination.resolvers

            endpoint.setResolvedInheritedRelationships(
                superEndpoint
                    .combinedRelationships
                // replace any resolvers for (sub relationships) with those used to resolve the inheritance (e.g. based on our own properties)
                // we can't resolve path parameters based on properties of the inheritance
                    .replaceAll(resolvers: resolvers)
            )
        }
    }
}

/// A `BuildingEndpoint` is used for the relationship collection process for a given `Endpoint`.
///
/// As Relationship information can be sourced from many different locations,
/// there is a potential to name collisions.
/// We don't actively prevent name collisions (as a potential Exporter is not impacted by colliding names),
/// but rather let relationship shadow each other depending of their importance.
/// The order of shadowing is defined as follows (while a Relationship of the listed types
/// shadows any relationships previous in the list):
/// - Inherited Relationships (derived from implicit and explicit inheritance)
/// - Structural Relationships (derived from the (Path)Component structure)
/// - Explicit Declaration of Relationships
///   - Type based relationships (e.g. Relationship DSL)
///   - Use of `Relationship` instances.
///
/// Name collisions inside a certain type are either not possible (e.g. for structural relationships)
/// or result in undefined behavior (depending on the order of execution):
///  - Explicit declarations: the user is responsible for not creating collisions.
///  - Inheritance: Shadowing inherited relationships is what you would expect from inheritance.
///                 You might want to used the `relationship(name:)` modifier on structural relationships
///                 to resolve them if possible.
private class BuildingEndpoint {
    /// The reference to the Endpoint.
    let reference: EndpointReference

    /// The default self relationship derived from the structure.
    private(set) lazy var structuralSelfRelationship: EndpointRelationship = {
        RelationshipBuilder.constructStructuralSelfRelationship(for: reference)
    }()
    /// Any Relationships derived from the structure
    private(set) lazy var structuralRelationships: [[EndpointPath]: EndpointRelationship] = {
        RelationshipBuilder.constructStructuralRelationships(for: reference)
    }()

    /// Defines a model for the self relationship created through inheritance (if this endpoint has a inheritance).
    private(set) var inheritedSelfRelationship: EndpointRelationship?

    /// Any relationships created from explicit type hints.
    private(set) var explicitTypedRelationships: [[EndpointPath]: EndpointRelationship] = [:]
    /// Relationships created from `Relationship` instances.
    private(set) var explicitRelationships: [[EndpointPath]: EndpointRelationship] = [:]

    /// Any `EndpointRelationship`s which may be inherited.
    /// Empty if there is no `inheritedSelfRelationship`
    private(set) var inheritedRelationships: [EndpointRelationship]? // swiftlint:disable:this discouraged_optional_collection

    private var built = false
    lazy var combinedRelationships: [EndpointRelationship] = {
        built = true

        guard let inheritedRelationships = inheritedSelfRelationship != nil ? inheritedRelationships : [] else {
            fatalError("Tried accessing inherited of \(reference) although they weren't resolved yet!")
        }

        // The order of combination strongly reflects our name shadowing logic as described above.
        return [
            inheritedRelationships,
            Array(structuralRelationships.values),
            Array(explicitTypedRelationships.values),
            Array(explicitRelationships.values)
        ].reduce(into: []) { result, relationships in
            result.append(contentsOf: relationships)
        }
    }()

    init(for reference: EndpointReference) {
        self.reference = reference
    }

    func build() {
        let result = RelationshipBuilderResult(
            structuralSelfRelationship: structuralSelfRelationship,
            inheritedSelfRelationship: inheritedSelfRelationship,
            relationships: combinedRelationships
        )

        reference.resolveAndMutate { endpoint in
            endpoint.initRelationships(with: result)
        }
    }

    func addInheritance(from: EndpointReference, with resolvers: [AnyPathParameterResolver]) {
        precondition(!built, "Tried altering relationships for \(reference) after they were built!")
        let destination = RelationshipDestination(self: from, resolvers: resolvers)

        if var inherited = inheritedSelfRelationship,
           // a explicit inheritance definition might override a implicit inheritance
           // thus we do the path check, if it differs we jump to else and completely override the relationship
           inherited.path == destination.destinationPath {
            inherited.add(destination: destination)
            inheritedSelfRelationship = inherited
        } else {
            inheritedSelfRelationship = EndpointRelationship(destination: destination)
        }
    }

    func addDestinationFromExplicitTyping(name: String,
                                          destination reference: EndpointReference,
                                          with resolvers: [AnyPathParameterResolver]) {
        precondition(!built, "Tried altering relationships for \(reference) after they were built!")
        let destination = RelationshipDestination(name: name, destination: reference, resolvers: resolvers)

        if var existing = explicitTypedRelationships[destination.destinationPath] {
            existing.add(destination: destination)
            explicitTypedRelationships[destination.destinationPath] = existing
        } else {
            explicitTypedRelationships[destination.destinationPath] = EndpointRelationship(destination: destination)
        }
    }

    func addRelationshipInstance(_ relationship: EndpointRelationship) {
        precondition(!built, "Tried altering relationships for \(reference) after they were built!")
        if var existing = explicitRelationships[relationship.path] {
            // If a user overwrites their own `Relationship` instances its their fault.
            existing.merge(with: relationship)
            explicitRelationships[relationship.path] = existing
        } else {
            explicitRelationships[relationship.path] = relationship
        }
    }

    func setResolvedInheritedRelationships(_ inherited: [EndpointRelationship]) {
        precondition(!built, "Tried altering relationships for \(reference) after they were built!")
        inheritedRelationships = inherited
    }

    func selfRelationshipResolvers() -> [AnyPathParameterResolver] {
        guard let destination = inheritedSelfRelationship?.get(for: reference.operation)
            ?? structuralSelfRelationship.get(for: reference.operation) else {
            fatalError("Failed to retrieve the self relationship for \(reference)")
        }
        return destination.resolvers
    }
}


// MARK: Structural Relationships
extension RelationshipBuilder {
    static func constructStructuralSelfRelationship(for reference: EndpointReference) -> EndpointRelationship {
        let node = reference.node
        var relationship = EndpointRelationship(path: node.absolutePath)

        for endpoint in node.endpoints.values {
            relationship.addEndpoint(self: endpoint)
        }

        return relationship
    }

    static func constructStructuralRelationships(for reference: EndpointReference) -> [[EndpointPath]: EndpointRelationship] {
        constructStructuralRelationships(for: reference.node)
    }

    static func constructStructuralRelationships(for node: EndpointsTreeNode) -> [[EndpointPath]: EndpointRelationship] {
        guard node.finishedConstruction else {
            fatalError("Constructed endpoint relationships although the tree wasn't finished parsing!")
        }

        var relationships: [[EndpointPath]: EndpointRelationship] = [:]

        for child in node.children {
            let operations = Operation.allCases
            collectRelationships(on: child,
                                 collecting: &relationships,
                                 searchList: operations,
                                 hiddenOperations: Set(minimumCapacity: operations.count / 2))
        }

        return relationships
    }

    /// This method builds all STRUCTURAL Relationships.
    /// It must be called on a subtree of the desired source node (see `constructRelationships()`).
    /// This method will recursively traverse all nodes of the subtree until it finds
    /// a `Endpoint` for every `Operation`.
    ///
    /// - Parameters:
    ///   - node: The current `EndpointsTreeNode` to anaylze the structure of.
    ///   - relationships: The array to collect all the `EndpointRelationship` instances.
    ///   - searchList: Contains all the Operations to still search for relationships.
    ///   - hiddenOperations: The DSL allows to hide certain paths from Relationship indexing.
    ///         The `Handler.hideLink(...)` modifier can be used in a way to only hide Handlers with
    ///         a certain `Operation`. This property holds the `Operation` which are hidden for the given subtree.
    ///   - respectHidden: Defines if we encountered a hideLink previously and must respect the hiddenOperations set.
    ///   - namePrefix: Prefix to prepend to the relationship name.
    ///   - relativeNamingPath: A relative path use for naming.
    ///   - nameOverride: If defined, this value will override the relationship name.
    private static func collectRelationships(
        on node: EndpointsTreeNode,
        collecting relationships: inout [[EndpointPath]: EndpointRelationship],
        searchList: [Operation],
        hiddenOperations: Set<Operation>,
        namePrefix: String = "",
        relativeNamingPath: [EndpointPath] = [],
        nameOverride: String? = nil
    ) {
        let path = node.storedPath.path
        let pathContext = node.storedPath.context

        var prefix = namePrefix
        var override = pathContext.relationshipName ?? nameOverride

        var relativePath = relativeNamingPath
        relativePath.append(path)

        if pathContext.isGroupEnd, let name = override {
            prefix += name
            override = nil
            relativePath = []
        }

        var hiddenOperations = hiddenOperations
        for hiddenOperation in pathContext.hiddenOperations {
            hiddenOperations.insert(hiddenOperation)
        }

        var searchList = searchList
        var relationship: EndpointRelationship?

        for (operation, endpoint) in node.endpoints {
            if let index = searchList.firstIndex(of: operation) {
                // if the operation is in our search list, we create a relationship for it and remove it from the searchList
                searchList.remove(at: index)

                if relationship == nil {
                    relationship = EndpointRelationship(path: node.absolutePath)
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

        for child in node.children {
            collectRelationships(on: child,
                                 collecting: &relationships,
                                 searchList: searchList,
                                 hiddenOperations: hiddenOperations,
                                 namePrefix: prefix,
                                 relativeNamingPath: relativePath,
                                 nameOverride: override)
        }
    }
}
