//
// Created by Andreas Bauer on 27.01.21.
//

import Foundation

/// This structure is a temporary storage for collecting `Relationship` instances.
struct RelationshipInstance {
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

    mutating func addSource<H: Handler>(_ endpoint: RelationshipEndpoint<H>) {
        sources.insert(endpoint.reference)
    }

    mutating func addDestination<H: Handler>(_ endpoint: RelationshipEndpoint<H>) {
        destinations.insert(endpoint.reference)
    }
}


// MARK: RelationshipBuilder

extension RelationshipInstance {
    func build() -> [EndpointReference: EndpointRelationship] {
        validateDestinations()

        precondition(!sources.isEmpty, """
                                       Sources for the `RelationshipInstance` '\(name)' was empty! \
                                       Please define at least one destination using the `relationship(to:)` modifier.
                                       """)

        return sources.reduce(into: [:]) { result, source in
            precondition(!destinations.isEmpty, """
                                                Destinations for the `RelationshipInstance` '\(name)' was empty! \
                                                Please define at least one destination using the `destination(of:)` modifier.
                                                """)

            var relationship = EndpointRelationship(path: destinationPath)

            for destination in destinations {
                let destinationEndpoint = destination.resolve()
                relationship.addEndpoint(destinationEndpoint, name: name)
            }

            precondition(result[source] == nil, "Encountered duplicate sources \(source) for a `RelationshipInstance` '\(name)'")
            result[source] = relationship
        }
    }

    private func validateDestinations() {
        var set = Set<[EndpointPath]>()

        for destination in destinations {
            guard !sources.contains(destination) else {
                preconditionFailure("""
                                    The Relationship(name: \(name)) defined a source which was also defined as a destination. \
                                    The 'self' link is always defined and can't be manually added.
                                    """)
            }

            set.insert(destination.absolutePath)

            // uniqueness of `Operation` is already checked inside the `EndpointsTreeNode.addEndpoint(...)`

            if set.count != 1 {
                preconditionFailure("""
                                    The Relationship(name: \(name)) defined destinations which are not located under the same path. \
                                    Destinations of a Relationship instance must be declared under the same path!
                                    """)
            }
        }
    }
}
