//
//  RelationshipEndpoint.swift
//
//
//  Created by Max Obermeier on 14.06.21.
//

import Foundation


public protocol AnyRelationshipEndpoint: CustomStringConvertible, Blackboard, ParameterCollection {
    var absolutePath: [EndpointPath] { get }

    var inheritsRelationship: Bool { get }
    
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
}

protocol _AnyRelationshipEndpoint: AnyRelationshipEndpoint {
    /// This property holds a `EndpointReference` for the given `Endpoint`.
    /// The reference can be resolve using `EndpointReference.resolve()`.
    ///
    /// The reference can only be accessed once the `Endpoint` is fully inserted into the EndpointsTree.
    ///
    /// - Returns: `EndpointReference` to the given `Endpoint´.
    var reference: EndpointReference { get }
    
    /// Internal method to initialize the endpoint with built relationships.
    /// - Parameter result: The `RelationshipBuilderResult` handing over all relationships for the endpoint.
    mutating func initRelationships(with result: RelationshipBuilderResult)
}


/// Models a single Endpoint which is identified by its PathComponents and its operation
public struct RelationshipEndpoint<H: Handler>: _AnyRelationshipEndpoint {
    private let blackboard: Blackboard

    var inserted = false
    
    /// This property holds a `EndpointReference` for the given `Endpoint`.
    /// The reference can be resolve using `EndpointReference.resolve()`.
    ///
    /// The reference can only be accessed once the `Endpoint` is fully inserted into the EndpointsTree.
    ///
    /// - Returns: `EndpointReference` to the given `Endpoint´.
    var reference: EndpointReference {
        guard let endpointReference = storedReference else {
            fatalError("Tried accessing the `EndpointReference` of the Endpoint of \(H.self) although it wasn't fully inserted into the EndpointsTree")
        }
        return endpointReference
    }
    private var storedReference: EndpointReference?

    public let handler: H

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

    init(
        handler: H,
        blackboard: Blackboard
    ) {
        self.handler = handler
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

    mutating func inserted(at treeNode: EndpointsTreeNode) {
        inserted = true
        storedAbsolutePath = treeNode.absolutePath.scoped(on: self)
        storedReference = EndpointReference(on: treeNode, of: self)
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

extension RelationshipEndpoint: CustomDebugStringConvertible {
    public var debugDescription: String {
        String(describing: self.handler)
    }
}

extension RelationshipEndpoint: CustomStringConvertible {
    public var description: String {
        self[HandlerDescription.self]
    }
}

public extension AnyRelationshipEndpoint {
    /// Provides the ``EndpointParameters`` that correspond to the ``Parameter``s defined on the ``Handler`` of this ``RelationshipEndpoint``.
    var parameters: EndpointParameters { self[EndpointParameters.self] }
}
