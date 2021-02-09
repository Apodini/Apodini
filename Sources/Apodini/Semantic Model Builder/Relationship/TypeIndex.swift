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
    private let relationshipBuilder: RelationshipBuilder

    /// Contains automatically collected and explicitly defined inheritances
    fileprivate var collectedInheritanceCandidates: [EndpointReference: Set<IndexedRelationshipInheritanceCandidate>] = [:]
    /// Contains explicitly defined .reference and .link relationships
    private var collectedOtherCandidates: [SomeRelationshipSourceCandidate] = []


    init(from typeIndexBuilder: TypeIndexBuilder, buildingWith relationshipBuilder: RelationshipBuilder) {
        self.logger = typeIndexBuilder.logger

        let result = typeIndexBuilder.build()
        self.typeIndex = result.typeIndex
        self.relationshipBuilder = relationshipBuilder

        for (reference, candidates) in result.sourceCandidates {
            // non inheritance candidates (which are not generated right now) might have some implications on
            // the order of calling `endpoint.resolveInheritanceRelationship(...)`.
            precondition(candidates.contains(where: { $0.type == .inheritance }),
                         "TypeIndex is not intended to handle non .inheritance auto generated type information!")

            let indexedCandidates = candidates.map { IndexedRelationshipInheritanceCandidate(from: $0, type: .implicit) }
            collectedInheritanceCandidates[reference] = Set(indexedCandidates)
        }

        // call the RelationshipBuilder to index their explicitly defined relationship candidates
        index(candidates: relationshipBuilder.collectedRelationshipCandidates)
    }

    private subscript(objectId: ObjectIdentifier, operation: Operation) -> TypeIndexEntry? {
        typeIndex[TypeIdentifier(objectId: objectId, operation: operation)]
    }

    private mutating func index(candidates collectedCandidates: [PartialRelationshipSourceCandidate]) {
        for candidate in collectedCandidates {
            if candidate.type == .inheritance {
                var set = collectedInheritanceCandidates[candidate.reference, default: Set()]

                let indexed = IndexedRelationshipInheritanceCandidate(from: candidate, type: .explicit)
                if let replaced = set.update(with: indexed),
                   replaced.definitionType != .implicit {
                    // we replaced a explicit inheritance definition with a explicit one (user defined some conflicting information)

                    fatalError("""
                               Conflicting relationship inheritance definition for \(candidate.reference):
                               Tried overwriting defined inheritance \(replaced.debugDescription) \
                               with second inheritance definition \(indexed.debugDescription)!
                               """)
                }

                collectedInheritanceCandidates[candidate.reference] = set
            } else {
                collectedOtherCandidates.append(candidate)
            }
        }
    }

    /// Public Interfacing method to be called as last step to resolve all indexed candidates.
    func resolve() {
        let inheritanceCandidates = sortedInheritanceCandidates(candidates: collectedInheritanceCandidates)

        logger.debug("Starting to resolve inheritances(\(inheritanceCandidates.count))...")

        for candidate in inheritanceCandidates {
            resolve(candidate: candidate.ensureResolved(using: relationshipBuilder), type: candidate.definitionType)
        }

        logger.debug("Starting to resolve links and references(\(collectedOtherCandidates.count))...")

        for candidate in collectedOtherCandidates {
            resolve(candidate: candidate.ensureResolved(using: relationshipBuilder), type: .explicit)
        }
    }

    private func resolve(candidate: SomeRelationshipSourceCandidate, type: DefinitionType) {
        // we need to check afterwards if we found ANY destinations
        var foundSome = false

        let source = candidate.reference
        let objectId = ObjectIdentifier(candidate.destinationType)

        for operation in Operation.allCases {
            guard let entry = self[objectId, operation] else {
                continue
            }

            if failsParameterResolvability(for: candidate, on: entry, type: type) {
                continue
            }

            let destination = entry.reference
            foundSome = true

            switch candidate.type {
            case .inheritance:
                logger.debug("[TypeIndex] Adding inheritance Relationship from \(source.debugDescription) to \(destination.debugDescription)")

                relationshipBuilder.addRelationshipInheritance(
                    at: source,
                    from: destination,
                    resolvers: candidate.resolvers
                )
            case let .reference(name), let .link(name):
                logger.debug("[TypeIndex] Adding relationship \(candidate.type) from \(source.debugDescription) to \(destination.debugDescription)")

                relationshipBuilder.addDestinationFromExplicitTyping(
                    at: source,
                    name: name,
                    destination: destination,
                    with: candidate.resolvers
                )
            }
        }

        if !foundSome, case .explicit = type {
            // If the user explicitly state that they want that relationship, we fail if we can't get it
            fatalError("""
                       Explicit definition of \(candidate) couldn't be resolved. \
                       Didn't find a destination for the given type in the TypeIndex.
                       """)
        }
    }

    /// This method checks the resolvability of path parameters of the relationship destination.
    /// PathParameter might not be required to be resolvable depending on the relationship type.
    /// The method might go into fatal error if the path parameter are not resolvable for a explicit definition.
    ///
    /// - Parameters:
    ///   - candidate: The `SomeRelationshipSourceCandidate` to check for.
    ///   - entry: The `TypeIndexEntry` representing the destination of the relationship.
    ///   - type: The type of relationship definition.
    /// - Returns: Returns `true` if the given candidate fails the parameter check.
    private func failsParameterResolvability(for candidate: SomeRelationshipSourceCandidate, on entry: TypeIndexEntry, type: DefinitionType) -> Bool {
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
                               Explicit definition of \(candidate) couldn't resolve all path parameter \
                               from \(candidate.reference) to destination \(entry.reference).
                               The following path parameter of the destination are missing a resolver: \(
                                   unresolvedPathParameters.map { "{\($0.name)}" }.joined(separator: ", ")
                               )
                               """)
                }

                return true
            }

            if !unusedResolvers.isEmpty, case .explicit = type {
                logger.warning("""
                               [TypeIndex] The definition of \(candidate) contains resolvers with are unused: \
                               \(unusedResolvers.map { $0.description }.joined(separator: ", ")).
                               """)
            }
        }

        return false
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
        buildInheritanceIndex(for: candidates, into: &inheritanceIndex)

        // Step 2: Check that it doesn't contain circles
        for index in inheritanceIndex.values {
            checkCircles(index: index, inheritanceIndex: inheritanceIndex)
        }

        // Step 3: Evaluate inheritance counters
        for type in inheritanceIndex.keys {
            if var index = inheritanceIndex[type], index.maxInheritanceDepth == nil {
                calcInheritanceDepth(for: &index, in: &inheritanceIndex)
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
                result.append(contentsOf: index.inheritanceCandidates)
            }
    }

    /// Creates the actual inheritance index used to for cycle checking and calculating the inheritance depth.
    /// - Parameters:
    ///   - candidates: The candidates to build the index out.
    ///   - index: The index to write into.
    private func buildInheritanceIndex(
        for candidates: [EndpointReference: Set<IndexedRelationshipInheritanceCandidate>],
        into index: inout [ObjectIdentifier: IndexedInheritance]
    ) {
        for sets in candidates.values {
            for candidate in sets {
                let inheritedType = candidate.destinationType
                let subType = candidate.reference.responseType

                let identifier = ObjectIdentifier(inheritedType)

                // we have candidates which are defined to inherit from the same type, those are not problematic
                // (e.g. /authenticated -> User might inherit from /user/:userId -> User)
                // => below we ensure that this type duplicate is not added to `subTypes`

                if var inheritance = index[identifier] {
                    if subType != inheritedType {
                        inheritance.subtypes.append(subType)
                    }
                    inheritance.inheritanceCandidates.append(candidate)

                    index[identifier] = inheritance
                } else {
                    index[identifier] = IndexedInheritance(
                        inheritedType: candidate.destinationType,
                        subtypes: subType != inheritedType ? [subType] : [],
                        inheritanceCandidates: [candidate],
                        maxInheritanceDepth: nil)
                }
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

    /// This method evaluates the value for the `IndexedInheritance.maxInheritanceDepth` property.
    /// This value defines the maximum count of children for a given type.
    /// This method calls itself recursively and thus other `IndexedInheritance` are touched to evaluate
    /// their `maxInheritanceDepth`, reducing calls needed for other calculations.
    ///
    /// - Parameters:
    ///   - index: The index instance to calculate the depth value for.
    ///   - inheritanceIndex: The InheritanceIndex to operate on.
    /// - Returns: Returns the
    @discardableResult
    private func calcInheritanceDepth(for index: inout IndexedInheritance, in inheritanceIndex: inout [ObjectIdentifier: IndexedInheritance]) -> Int {
        if let depth = index.maxInheritanceDepth {
            return depth
        }

        let maxDepth = index.subtypes
            .map { subtype -> Int in
                precondition(subtype != index.inheritedType, "Inconsistency in `IndexedInheritance`: `subType` contains `inheritedType`")

                let identifier = ObjectIdentifier(subtype)

                if var subIndex = inheritanceIndex[identifier] {
                    return calcInheritanceDepth(for: &subIndex, in: &inheritanceIndex)
                } else {
                    return 0
                }
            }
            .max()

        var depth: Int = 0
        if let calculatedDepth = maxDepth {
            depth = calculatedDepth + 1
        }

        index.maxInheritanceDepth = depth
        inheritanceIndex[ObjectIdentifier(index.inheritedType)] = index

        return depth
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
    func ensureResolved(using builder: RelationshipBuilder) -> RelationshipSourceCandidate {
        candidate.ensureResolved(using: builder)
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
