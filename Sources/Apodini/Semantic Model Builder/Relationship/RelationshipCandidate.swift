//
// Created by Andreas Bauer on 23.01.21.
//

enum RelationshipType: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    /// All relationships from the destination are inherited (including the self relationship).
    /// This requires that the `RelationshipSourceCandidate` contains resolvers
    /// for all path parameters of the relationship destination.
    case inheritance
    /// A reference describes a special case of Relationship where properties
    /// of the returned data is REPLACED by the relationship (e.g. a link in the REST exporter).
    /// This type requires that the `RelationshipSourceCandidate` contains resolvers
    /// for all path parameters of the relationship destination.
    case reference(name: String)
    /// A link is any kind of Relationship. It doesn't enforce any path parameters to be resolved
    /// (although it can be resolved if wanted).
    case link(name: String)

    var description: String {
        switch self {
        case .inheritance:
            return "inheritance"
        case .reference:
            return "reference"
        case .link:
            return "link"
        }
    }

    var debugDescription: String {
        switch self {
        case .inheritance:
            return "inheritance"
        case let .reference(name):
            return #"reference(name: "\#(name)")"#
        case let .link(name):
            return #"link(name: "\#(name)")"#
        }
    }

    var checkResolvers: Bool {
        if case .link = self {
            return false
        }
        return true
    }

    func hash(into hasher: inout Hasher) {
        description.hash(into: &hasher)
    }

    static func == (lhs: RelationshipType, rhs: RelationshipType) -> Bool {
        switch (lhs, rhs) {
        case (.inheritance, .inheritance),
             (.reference, .reference),
             (.link, .link):
            return true
        default:
            return false
        }
    }
}


/// Defines a relationship source candidate, either a resolved `RelationshipSourceCandidate` or unresolved `PartialRelationshipSourceCandidate`
protocol SomeRelationshipSourceCandidate: CustomDebugStringConvertible {
    var type: RelationshipType { get }
    var destinationType: Any.Type { get }
    var reference: EndpointReference { get }
    var resolvers: [AnyPathParameterResolver] { get }

    /// Returns a resolved version of the candidate representation
    func ensureResolved(using builder: RelationshipBuilder) -> RelationshipSourceCandidate
}

/// Represents a candidate for a `EndpointRelationship` create using type information
/// (either completely automatically or by type hints from the user)
struct RelationshipSourceCandidate: SomeRelationshipSourceCandidate {
    var debugDescription: String {
        "RelationshipCandidate(\(type.debugDescription), targeting: \(destinationType), resolvers: \(resolvers.count))"
    }

    /// Defines the type of `RelationshipSourceCandidate`. See `RelationshipType`.
    /// For `.reference` type this implicitly defines the name of the relationship.
    let type: RelationshipType

    /// Defines the type of the destination in the `TypeIndex`
    let destinationType: Any.Type
    /// Defines the reference to the source
    let reference: EndpointReference
    let resolvers: [AnyPathParameterResolver]

    /// Initializes a `RelationshipSourceCandidate` with type of inheritance.
    init(destinationType: Any.Type, reference: EndpointReference, resolvers: [AnyPathParameterResolver]) {
        self.type = .inheritance
        self.destinationType = destinationType
        self.reference = reference
        self.resolvers = resolvers
    }

    fileprivate init(from partialCandidate: PartialRelationshipSourceCandidate,
                     reference: EndpointReference,
                     using builder: RelationshipBuilder) {
        self.type = partialCandidate.type
        self.destinationType = partialCandidate.destinationType
        self.reference = reference

        var parameterResolvers: [AnyPathParameterResolver]
        if case .inheritance = type {
            parameterResolvers = reference.absolutePath.listPathParameters().resolvers()
        } else {
            // We take all resolver used for inheritance into account in order for this to work
            // the `TypeIndex.resolve` steps MUST parse inheritance candidates FIRST.
            parameterResolvers = builder.selfRelationshipResolvers(for: reference)
        }

        // inserting manually defined resolvers BEFORE the "automatically" derived path parameter resolvers
        // to avoid conflicting resolvers (e.g. path parameter resolving the same parameter as property resolver)
        parameterResolvers.insert(contentsOf: partialCandidate.resolvers, at: 0)
        self.resolvers = parameterResolvers
    }

    func ensureResolved(using builder: RelationshipBuilder) -> RelationshipSourceCandidate {
        self
    }
}

/// A `RelationshipSourceCandidate` but without the scope of the `Endpoint`
/// meaning still missing the `EndpointReference` and missing any `PathParameterResolver` in the `resolvers`.
public struct PartialRelationshipSourceCandidate: SomeRelationshipSourceCandidate {
    public var debugDescription: String {
        "PartialRelationshipSourceCandidate(\(type.debugDescription), targeting: \(destinationType), resolvers: \(resolvers.count))"
    }

    /// Defines the type of `PartialRelationshipSourceCandidate`. See `RelationshipType`.
    /// For `.reference` type this implicitly defines the name of the relationship.
    let type: RelationshipType

    /// Defines the type of the destination in the `TypeIndex`
    let destinationType: Any.Type
    let resolvers: [AnyPathParameterResolver]

    /// Defines the reference to the source
    var reference: EndpointReference {
        guard let reference = storedReference else {
            fatalError("Tried accessing reference of PartialRelationshipSourceCandidate which wasn't linked to an Endpoint yet!")
        }
        return reference
    }
    var storedReference: EndpointReference?

    /// Initializes a `RelationshipSourceCandidate` with type of inheritance.
    init(destinationType: Any.Type, resolvers: [AnyPathParameterResolver]) {
        self.type = .inheritance
        self.destinationType = destinationType
        self.resolvers = resolvers
    }

    /// Initializes a `RelationshipSourceCandidate` with type of reference.
    init(reference name: String, destinationType: Any.Type, resolvers: [AnyPathParameterResolver]) {
        self.type = .reference(name: name)
        self.destinationType = destinationType
        self.resolvers = resolvers
    }

    /// Initializes a `RelationshipSourceCandidate` with type of reference.
    init(link name: String, destinationType: Any.Type, resolvers: [AnyPathParameterResolver] = []) {
        self.type = .link(name: name)
        self.destinationType = destinationType
        self.resolvers = resolvers
    }

    mutating func link(to endpoint: _AnyRelationshipEndpoint) {
        storedReference = endpoint.reference
    }

    func ensureResolved(using builder: RelationshipBuilder) -> RelationshipSourceCandidate {
        RelationshipSourceCandidate(from: self, reference: reference, using: builder)
    }
}

extension Array where Element == PartialRelationshipSourceCandidate {
    func linked(to endpoint: _AnyRelationshipEndpoint) -> [PartialRelationshipSourceCandidate] {
        map {
            var candidate = $0
            candidate.link(to: endpoint)
            return candidate
        }
    }
}

extension Array where Element == RelationshipSourceCandidate {
    /// Index the `RelationshipSourceCandidate` array by the `EndpointReference` stored in `reference`.
    func referenceIndexed() -> CollectedRelationshipCandidates {
        var candidates: CollectedRelationshipCandidates = [:]

        for sourceCandidate in self {
            var collectedCandidates = candidates[sourceCandidate.reference, default: []]
            collectedCandidates.append(sourceCandidate)
            candidates[sourceCandidate.reference] = collectedCandidates
        }

        return candidates
    }
}
