//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini

/// The protocol that defines the output of the structure retrieval of a `StructureExporter`.
/// The default implementation of it is `DeployedSystem`.
/// If you want to retrieve the structure in a custom type, adhere to the following:
///     1. Conform your type to this protocol
///     2. Return the type in your implementation of `retrieveStructure` of `StructureExporter`.
///     3. In your deployment provider, specify the decode type of `retrieveSystemStructure` with your type.
public protocol AnyDeployedSystem: Codable {
    var deploymentProviderId: DeploymentProviderID { get }
    
    /// The nodes the system consists of
    var nodes: Set<DeployedSystemNode> { get }
}

/// The structure of a deployed system.
/// A deployed system is a distributed system consisting of one or more nodes.
/// Each node implements one or more of the deployed `WebService`'s endpoints.
/// - Note: There may be more than one instances of a node running at a given time,
///   for example when deploying to a platform which supports scaling.
public struct DeployedSystem: AnyDeployedSystem {
    /// Identifier of the deployment provider used to create the deployment
    public let deploymentProviderId: DeploymentProviderID
    
    /// The nodes the system consists of
    public var nodes: Set<DeployedSystemNode>

    public init(
        deploymentProviderId: DeploymentProviderID,
        nodes: Set<DeployedSystemNode>
    ) throws {
        self.deploymentProviderId = deploymentProviderId
        self.nodes = nodes
        try nodes.assertHandlersLimitedToSingleNode()
    }
}


extension AnyDeployedSystem {
    /// Fetch one of the system's nodes, by id.
    public func node(withId nodeId: DeployedSystemNode.ID) -> DeployedSystemNode? {
        nodes.first { $0.id == nodeId }
    }
    
    /// Returns the node which exports an endpoint with the specified handler identifier.
    /// - Note: A system should never contain multiple nodes exporting the same endpoint,
    public func nodeExportingEndpoint(withHandlerId handlerId: AnyHandlerIdentifier) -> DeployedSystemNode? {
        nodes.first { $0.exportedEndpoints.contains { $0.handlerId == handlerId } }
    }
}

/// A node within the deployed system
public struct DeployedSystemNode: Codable, Identifiable, Hashable, Equatable {
    /// ID of this node
    public let id: String
    /// exported handler ids
    public let exportedEndpoints: Set<ExportedEndpoint>
    /// Additional deployment provider specific data
    public private(set) var userInfo: Data?

    public init(id: String, exportedEndpoints: Set<ExportedEndpoint>) {
        self.id = id
        self.exportedEndpoints = exportedEndpoints
    }

    public init<T: Encodable>(id: String, exportedEndpoints: Set<ExportedEndpoint>, userInfo: T) throws {
        self.id = id
        self.exportedEndpoints = exportedEndpoints
        try setUserInfo(userInfo, type: T.self)
    }
    
    
    public mutating func setUserInfo<T: Encodable>(_ value: T?, type _: T.Type = T.self) throws {
        self.userInfo = try value.map { try $0.encodeToJSON() }
    }
    
    
    public func readUserInfo<T: Decodable>(as _: T.Type) -> T? {
        userInfo.flatMap { try? T(decodingJSON: $0) }
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: DeployedSystemNode, rhs: DeployedSystemNode) -> Bool {
        lhs.id == rhs.id
    }
    
    
    public func withUserInfo<T: Encodable>(_ userInfo: T?) throws -> Self {
        var copy = self
        try copy.setUserInfo(userInfo, type: T.self)
        return copy
    }
}

extension DeploymentGroup {
    /// Checks whether this group should contain the exported endpoint
    public func matches(exportedEndpointInfo: CollectedEndpointInfo) -> Bool {
        handlerTypes.contains(exportedEndpointInfo.handlerType) || handlerIds.contains(exportedEndpointInfo.endpoint[AnyHandlerIdentifier.self])
    }
}

extension Sequence where Element == DeployedSystemNode {
    /// Asserts that, in the sequence of nodes, every handler appears in only one node
    public func assertHandlersLimitedToSingleNode() throws {
        var exportedHandlerIds = Set<AnyHandlerIdentifier>()
        // make sure a handler isn't listed in multiple nodes
        for node in self {
            for endpoint in node.exportedEndpoints {
                guard exportedHandlerIds.insert(endpoint.handlerId).inserted else {
                    throw ApodiniDeployBuildSupportError(
                        message: "Handler with id '\(endpoint.handlerId)' appears in multiple deployment groups, which is illegal."
                    )
                }
            }
        }
    }
    
    /// Check that the sequence of nodes contains all endpoints from the other set
    public func assertContainsAllEndpointsIn(_ allEndpoints: Set<CollectedEndpointInfo>) throws {
        // make sure every handler appears in one node
        let exportedHandlerIds = Set(self.flatMap(\.exportedEndpoints).map(\.handlerId))
        let expectedHandlerIds = Set(allEndpoints.map { $0.endpoint[AnyHandlerIdentifier.self] })
        guard expectedHandlerIds == exportedHandlerIds else {
            assert(exportedHandlerIds.isSubset(of: expectedHandlerIds))
            // All handler ids which appear in one of the two sets, but not in both.
            // Since the set of exported handler ids is a subset of the set of all handler ids,
            // this difference is the set of all handlers which aren't exported by a node
            let diff = expectedHandlerIds.symmetricDifference(exportedHandlerIds)
            throw ApodiniDeployBuildSupportError(
                message: "Handler ids\(diff.map { "'\($0.rawValue)'" }.joined(separator: ", "))"
            )
        }
    }
}
