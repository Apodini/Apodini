//
// Created by Andreas Bauer on 19.01.21.
//

import Foundation

/// This structure is a temporary storage for collecting `Relationship` instances.
private struct RelationshipInstance {
    let name: String

    private(set) var sources: Set<EndpointReference> = Set()
    private(set) var destinations: Set<EndpointReference> = Set()

    var destinationPath: [EndpointPath] {
        guard let first = destinations.first else {
            preconditionFailure("Tried retrieving destinationPath for Relationship(name: \(name)) though no destinations were found!")
        }
        // this works, as we force all destinations to be located under the same path
        return first.absolutePath
    }

    init(name: String) {
        self.name = name
    }

    mutating func addSource<H: Handler>(_ endpoint: Endpoint<H>) {
        sources.insert(endpoint.reference())
    }

    mutating func addDestination<H: Handler>(_ endpoint: Endpoint<H>) {
        destinations.insert(endpoint.reference())
    }
}


/// The `RelationshipInstanceBuilder` is used to collect `Relationship` instances
/// manually defined by the user, to build `EndpointRelationship`s out of it.
struct RelationshipInstanceBuilder {
    private var collectedRelationshipInstances: [UUID: RelationshipInstance] = [:]
    private var collectedRelationshipCandidates: CollectedPartialRelationshipCandidates = [:]

    mutating func collectRelationshipCandidates<H: Handler>(for endpoint: Endpoint<H>, _ partialCandidates: [PartialRelationshipSourceCandidate]) {
        let reference = endpoint.reference()

        var collectedCandidates = collectedRelationshipCandidates[reference, default: []]
        collectedCandidates.append(contentsOf: partialCandidates)
        collectedRelationshipCandidates[reference] = collectedCandidates.linked(to: endpoint)
    }

    mutating func collectSources<H: Handler>(for endpoint: Endpoint<H>, _ relationships: [Relationship]) {
        for source in relationships {
            modifyRelationshipInstance(for: source) { instance in
                instance.addSource(endpoint)
            }
        }
    }

    mutating func collectDestinations<H: Handler>(for endpoint: Endpoint<H>, _ relationships: [Relationship]) {
        for destination in relationships {
            modifyRelationshipInstance(for: destination) { instance in
                instance.addDestination(endpoint)
            }
        }
    }

    private mutating func modifyRelationshipInstance(for relationship: Relationship, operation: (inout RelationshipInstance) -> Void) {
        var instance = collectedRelationshipInstances[relationship.id, default: RelationshipInstance(name: relationship.name)]
        precondition(instance.name == relationship.name, "Encountered Relationship with same id but different names (existent '\(instance.name)' didn't match '\(relationship.name)')")

        operation(&instance)

        collectedRelationshipInstances[relationship.id] = instance
    }

    func resolveInstances() {
        for instance in collectedRelationshipInstances.values {
            instance.build()
        }
    }

    func index(into typeIndex: inout TypeIndex) {
        typeIndex.index(candidates: collectedRelationshipCandidates)
    }
}

// MARK: RelationshipInstanceBuilder
extension RelationshipInstance {
    func build() {
        validateDestinations()

        precondition(!sources.isEmpty, """
                                            Sources for the `RelationshipInstance` '\(name)' was empty! \
                                            Please define at least one destination using the `relationship(to:)` modifier.
                                            """)

        for source in sources {
            precondition(!destinations.isEmpty, """
                                                Destinations for the `RelationshipInstance` '\(name)' was empty! \
                                                Please define at least one destination using the `destination(of:)` modifier.
                                                """)

            let node = source.resolveNode()
            var relationship = EndpointRelationship(path: destinationPath)

            for destination in destinations {
                let destinationEndpoint = destination.resolve()
                relationship.addEndpoint(destinationEndpoint, name: name)
            }

            node.addRelationship(at: source, relationship)
        }
    }

    private func validateDestinations() {
        _ = destinations.reduce(into: Set<[EndpointPath]>()) { result, destination in
            guard !sources.contains(destination) else {
                preconditionFailure("""
                                    The Relationship(name: \(name)) defined a source which was also defined as a destination. \
                                    The 'self' link is always defined and can't be manually added.
                                    """)
            }

            result.insert(destination.absolutePath)

            // uniqueness of `Operation` is already checked inside the `EndpointsTreeNode.addEndpoint(...)`

            if result.count != 1 {
                preconditionFailure("""
                                    The Relationship(name: \(name)) defined destinations which are not located under the same path. \
                                    Destinations of a Relationship instance must be declared under the same path!
                                    """)
            }
        }
    }
}
