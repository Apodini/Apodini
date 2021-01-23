//
// Created by Andreas Bauer on 16.01.21.
//

import Logging

/// Identifies a `TypeIndexEntry`.
/// A entry in the TypeIndex is defined by the `Content` type of the `Handler`
/// and the `Operation` of the `Handler`.
struct TypeIdentifier: Hashable {
    let objectId: ObjectIdentifier
    let operation: Operation
}

/// Represents a entry in the `TypeIndex`
struct TypeIndexEntry: CustomDebugStringConvertible {
    let type: Any.Type
    /// Reference of the handler where this type is returned
    let reference: EndpointReference
    /// PathParameters contained in the path to the Endpoint.
    /// Depending on the `RelationshipType` those need to resolvable from the source.
    let pathParameters: [AnyEndpointPathParameter]

    var debugDescription: String {
        reference.debugDescription
    }
}

typealias TypeIndexStorage = [TypeIdentifier: TypeIndexEntry]
typealias CollectedRelationshipCandidates = [EndpointReference: [RelationshipSourceCandidate]]
typealias CollectedPartialRelationshipCandidates = [EndpointReference: [PartialRelationshipSourceCandidate]]


struct TypeIndex {
    /// Defines how the relationship candidate was gathered.
    enum DefinitionType {
        /// The relationship candidate was automatically generated (e.g. by return type information)
        case implicit
        /// The relationship candidate was explicitly defined by the user.
        case explicit
    }

    private let logger: Logger

    private var typeIndex: TypeIndexStorage

    /// Contains automatically collected and explicitly defined inheritances
    fileprivate var collectedInheritanceCandidates: [EndpointReference: Set<IndexedRelationshipInheritanceCandidate>] = [:]
    /// Contains explicitly defined .reference and .link relationships
    private var collectedOtherCandidates: [EndpointReference: [SomeRelationshipSourceCandidate]] = [:]


    init(from typeIndexBuilder: TypeIndexBuilder) {
        self.logger = typeIndexBuilder.logger

        let result = typeIndexBuilder.build()
        self.typeIndex = result.typeIndex

        for (reference, candidates) in result.sourceCandidates {
            // non inheritance candidates (which are not generated right now) might have some implications on
            // the order of calling `endpoint.resolveInheritanceRelationship(...)`.
            precondition(candidates.contains(where: { $0.type == .inheritance }),
                         "TypeIndex is not intended to handle non .inheritance auto generated type information!")

            let indexedCandidates = candidates.map { IndexedRelationshipInheritanceCandidate(from: $0, type: .implicit) }
            collectedInheritanceCandidates[reference] = Set(indexedCandidates)
        }
    }

    subscript(objectId: ObjectIdentifier, operation: Operation) -> TypeIndexEntry? {
        typeIndex[TypeIdentifier(objectId: objectId, operation: operation)]
    }

    mutating func index(candidates collectedCandidates: CollectedPartialRelationshipCandidates) {
        for (reference, candidates) in collectedCandidates {
            for candidate in candidates {
                if candidate.type == .inheritance {
                    var set = collectedInheritanceCandidates[reference, default: Set()]

                    let indexed = IndexedRelationshipInheritanceCandidate(from: candidate, type: .explicit)
                    if let replaced = set.update(with: indexed),
                       replaced.definitionType != .implicit {
                        // we replaced a explicit inheritance definition with a explicit one (user defined some conflicting information)

                        fatalError("""
                                   Conflicting relationship inheritance definition for \(reference):
                                   Tried overwriting defined inheritance \(replaced.debugDescription) \
                                   with second inheritance definition \(indexed.debugDescription)!
                                   """)
                    }

                    collectedInheritanceCandidates[reference] = set
                } else {
                    var array = collectedOtherCandidates[reference, default: []]
                    array.append(candidate)
                    collectedOtherCandidates[reference] = array
                }
            }
        }
    }

    func resolve() {
        let inheritanceCandidates = sortedInheritanceCandidates(candidates: collectedInheritanceCandidates)
        // ordered array of Endpoints to call `resolveInheritanceRelationship` on
        var needsInheritanceResolving: [EndpointReference] = []

        logger.debug("Starting to resolve inheritances(\(inheritanceCandidates.count))...")

        for candidate in inheritanceCandidates {
            let node = candidate.reference.resolveNode()

            let resolved = resolve(on: node, for: candidate.reference, candidate: candidate.ensureResolved(), type: candidate.definitionType)
            if resolved {
                needsInheritanceResolving.append(candidate.reference)
            }
        }

        logger.debug("Starting to resolve links and references(\(collectedOtherCandidates.count))...")

        for (reference, candidates) in collectedOtherCandidates {
            let node = reference.resolveNode()

            for candidate in candidates {
                precondition(reference == candidate.reference,
                             """
                             Encountered inconsistency, candidate reference \(candidate.reference.debugDescription) \
                             didn't match the reference it was added for \(reference.debugDescription)!
                             """)

                _ = resolve(on: node, for: reference, candidate: candidate.ensureResolved(), type: .explicit)
            }
        }

        logger.debug("Resolving inherited relationships in order [\(needsInheritanceResolving.map { $0.description }.joined(separator: ", "))]")
        for reference in needsInheritanceResolving {
            reference.resolveAndMutate { $0.resolveInheritanceRelationship() }
        }
    }

    private func resolve(on node: EndpointsTreeNode,
                         for source: EndpointReference,
                         candidate: SomeRelationshipSourceCandidate,
                         type: DefinitionType) -> Bool {
        // we need to check afterwards if we found ANY destinations
        var foundSome = false
        let objectId = ObjectIdentifier(candidate.destinationType)

        for operation in Operation.allCases {
            guard let entry = self[objectId, operation] else {
                continue
            }

            if candidate.type.checkResolvers {
                // we loop through every path parameter of the destination and check if
                // the definition provides enough information to fill in those parameters at runtime (while request handling).
                // Additionally we track unused resolvers and print a warning of those.
                var unresolvedPathParameters: [AnyEndpointPathParameter] = []
                let unusedResolvers: [AnyPathParameterResolver] = candidate.resolvers
                    .resolvability(of: entry.reference.absolutePath, unresolved: &unresolvedPathParameters)

                if !unresolvedPathParameters.isEmpty {
                    if case .explicit = type {
                        fatalError("""
                                   Explicit definition of \(candidate) couldn't resolve all path parameter of from \(source) destination \(entry.reference).
                                   The following path parameter of the destination are missing a resolver: \(
                                       unresolvedPathParameters.map { "{\($0.name)}" }.joined(separator: ", ")
                                   )
                                   """)
                    }

                    continue
                }

                if !unusedResolvers.isEmpty, case .explicit = type {
                    logger.warning("""
                                   [TypeIndex] The definition of \(candidate) contains resolvers with are unused: \
                                   \(unusedResolvers.map { $0.description }.joined(separator: ", ")).
                                   """)
                }
            }

            foundSome = true

            switch candidate.type {
            case .inheritance:
                logger.debug("[TypeIndex] Adding inheritance Relationship to \(source.debugDescription) from \(entry.reference.debugDescription)")

                // allowOverwrite: strategy=.silence has the double meaning that those relationship candidates
                // are the result of our automatic return type analysis. Thus they may be overwritten
                // by an explicit definition.
                node.addRelationshipInheritance(
                    at: source,
                    from: entry.reference,
                    for: operation,
                    resolvers: candidate.resolvers
                )
            case let .reference(name), let .link(name):
                logger.debug("[TypeIndex] Adding relationship \(candidate.type) to \(source.debugDescription) from \(entry.reference.debugDescription)")
                // `source` and `candidate.reference` hold the reference to the source
                // `entry.reference` holds the reference to the destination
                let destination = RelationshipDestination(name: name, destination: entry.reference, resolvers: candidate.resolvers)
                node.addEndpointDestination(at: source, destination)
            }
        }

        if !foundSome, case .explicit = type {
            // If the user explicitly state that they want that relationship, we fail if we can't get it
            fatalError("""
                       Explicit definition of \(candidate) couldn't be resolved. \
                       Didn't find a destination for the given type in the TypeIndex.
                       """)
        }

        return foundSome
    }

    /// In order to properly parse multi-inheritance relationship inheritances we need to begin
    /// parsing the topmost inheritance. Thus we sort all our inheritance candidates
    /// by the amount of children, such that we can start parsing with the candidate with the most children.
    /// The order isn't really important for the `addRelationshipInheritance(...)` call,
    /// but for the `resolveInheritanceRelationship(...)` call which adds the relationships to the Endpoint
    /// from the super Endpoint (as a Endpoint adds all its relationships from its inherited Endpoint, and
    /// those should include relationships from its inherited Endpoint if it has one).
    /// The order of those calls is defined by the order returned by this function,
    /// as added to `needsInheritanceResolving`.
    ///
    /// This method creates such an order for given `candidates`.
    /// Additionally this method checks, that the Inheritance definition don't include any cyclic definitions.
    ///
    /// - Parameter candidates: Relationship inheritance candidates index by the Endpoint.
    /// - Returns: The sorted relationship candidates
    private func sortedInheritanceCandidates(
        candidates: [EndpointReference: Set<IndexedRelationshipInheritanceCandidate>]
    ) -> [IndexedRelationshipInheritanceCandidate] {
        /// Index by the destination type
        var inheritanceIndex: [ObjectIdentifier: IndexedInheritance] = [:]

        // Step 1: Create all inheritance indexes
        for sets in candidates.values {
            for candidate in sets {
                let inheritedType = candidate.destinationType
                let subType = candidate.reference.responseType

                let identifier = ObjectIdentifier(inheritedType)

                // we have candidates which are defined to inherit from the same type, those are not problematic
                // (e.g. /authenticated -> User might inherit from /user/:userId -> User)
                // => below we ensure that this type duplicate is not added to `subTypes`

                if var inheritance = inheritanceIndex[identifier] {
                    if subType != inheritedType {
                        inheritance.subtypes.append(subType)
                    }
                    inheritance.inheritanceCandidates.append(candidate)

                    inheritanceIndex[identifier] = inheritance
                } else {
                    inheritanceIndex[identifier] = IndexedInheritance(
                        inheritedType: candidate.destinationType,
                        subtypes: subType != inheritedType ? [subType] : [],
                        inheritanceCandidates: [candidate],
                        maxInheritanceDepth: nil)
                }
            }
        }

        // Step 2: Check that it doesn't contain circles
        for index in inheritanceIndex.values {
            checkCircles(index: index, inheritanceIndex: inheritanceIndex)
        }

        // Step 3: Evaluate inheritance counters
        for type in inheritanceIndex.keys {
            if var index = inheritanceIndex[type], index.maxInheritanceDepth == nil {
                index.maxInheritanceDepth = calcInheritanceDepth(for: index, in: &inheritanceIndex)
                inheritanceIndex[type] = index
            }
        }

        logger.debug("IndexedInheritances:")
        for (_, index) in inheritanceIndex {
            logger.debug("""
                          - \(index.inheritedType): \
                         [\(index.subtypes.map { "\($0)" }.joined(separator: ", "))] \
                         with: [\(index.inheritanceCandidates.map { $0.debugDescription }.joined(separator: ", ") )] \
                         num: \(index.maxInheritanceDepth ?? -1)
                         """)
        }

        // Step 4: Sort values by inheritance counters (desc)
        //   and turn them into an array of Relationship candidates again.
        return Array(inheritanceIndex.values)
            .sorted(by: { lhs, rhs in
                guard let lhsDepth = lhs.maxInheritanceDepth, let rhsDepth = rhs.maxInheritanceDepth else {
                    fatalError("Encountered inconsistency, undefined maxInheritanceDepth property")
                }
                return lhsDepth > rhsDepth // descending order
            })
            .reduce(into: []) { result, index in
                for candidate in index.inheritanceCandidates {
                    result.append(candidate)
                }
            }
    }

    /// Checks for circles in the inheritanceIndex for a given `index`
    /// - Parameters:
    ///   - index: The index to run the recursive check on.
    ///   - start: If defined, it defines the type we started on.
    ///   - inheritanceIndex: The inheritance index.
    ///   - visited: Array of types we visited (used for an helpful error output)
    private func checkCircles(
        index: IndexedInheritance,
        start: ObjectIdentifier? = nil,
        inheritanceIndex: [ObjectIdentifier: IndexedInheritance],
        visited: [Any.Type] = []) {
        let current = ObjectIdentifier(index.inheritedType)

        if start == current {
            fatalError("Detected cycle in inheritance chain of \(index.inheritedType): \(visited.map { "\($0)" }.joined(separator: " <- "))")
        }

        var visitedTypes = visited
        visitedTypes.append(index.inheritedType)

        for subtype in index.subtypes {
            precondition(subtype != index.inheritedType, "Inconsistency in `IndexedInheritance`: `subType` contains `inheritedType`")

            if let subIndex = inheritanceIndex[ObjectIdentifier(subtype)] {
                checkCircles(index: subIndex,
                             start: start ?? current,
                             inheritanceIndex: inheritanceIndex,
                             visited: visitedTypes)
            }
        }
    }

    private func calcInheritanceDepth(for index: IndexedInheritance, in inheritanceIndex: inout [ObjectIdentifier: IndexedInheritance]) -> Int {
        if let depth = index.maxInheritanceDepth {
            return depth
        }

        let maxDepth = index.subtypes
            .map { subtype -> Int in
                precondition(subtype != index.inheritedType, "Inconsistency in `IndexedInheritance`: `subType` contains `inheritedType`")

                let identifier = ObjectIdentifier(subtype)

                if var subIndex = inheritanceIndex[identifier] {
                    let depth = calcInheritanceDepth(for: subIndex, in: &inheritanceIndex)

                    subIndex.maxInheritanceDepth = depth
                    inheritanceIndex[identifier] = subIndex

                    return depth
                } else {
                    return 0
                }
            }
            .max()

        if let depth = maxDepth {
            return depth + 1
        } else {
            return 0
        }
    }
}

struct IndexedRelationshipInheritanceCandidate: Hashable, CustomDebugStringConvertible {
    var debugDescription: String {
        candidate.debugDescription
    }

    private let candidate: SomeRelationshipSourceCandidate
    let definitionType: TypeIndex.DefinitionType

    init(from candidate: SomeRelationshipSourceCandidate, type: TypeIndex.DefinitionType) {
        self.candidate = candidate
        self.definitionType = type
    }

    var type: RelationshipType {
        candidate.type
    }
    var destinationType: Any.Type {
        candidate.destinationType
    }
    var reference: EndpointReference {
        candidate.reference
    }

    /// Returns a resolved version of the candidate representation
    func ensureResolved() -> RelationshipSourceCandidate {
        candidate.ensureResolved()
    }

    func hash(into hasher: inout Hasher) {
        type.hash(into: &hasher)
        ObjectIdentifier(reference.responseType).hash(into: &hasher)
    }

    static func == (lhs: IndexedRelationshipInheritanceCandidate, rhs: IndexedRelationshipInheritanceCandidate) -> Bool {
        lhs.type == rhs.type && lhs.reference.responseType == rhs.reference.responseType
    }
}

struct IndexedInheritance {
    let inheritedType: Any.Type
    var subtypes: [Any.Type]

    var inheritanceCandidates: [IndexedRelationshipInheritanceCandidate]

    // Defines the biggest count of children
    var maxInheritanceDepth: Int?
}
