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
    public var nodes: Set<Node>
    
    /// Additional, deployment provider specific data
    public var userInfo: Data
    
    
    public init<T: Encodable>(
        deploymentProviderId: DeploymentProviderID,
        nodes: Set<Node>,
        userInfo: T?,
        userInfoType: T.Type = T.self
    ) throws {
        self.deploymentProviderId = deploymentProviderId
        self.nodes = nodes
        self.userInfo = try JSONEncoder().encode(userInfo)
        try nodes.assertHandlersLimitedToSingleNode()
    }
    
    
    public func readUserInfo<T: Decodable>(as _: T.Type) -> T? {
        try? T(decodingJSON: userInfo)
    }
}


extension DeployedSystem {
    /// Fetch one of the system's nodes, by id.
    public func node(withId nodeId: Node.ID) -> Node? {
        nodes.first { $0.id == nodeId }
    }
    
    /// Returns the node which exports an endpoint with the specified handler identifier.
    /// - Note: A system should never contain multiple nodes exporting the same endpoint,
    public func nodeExportingEndpoint(withHandlerId handlerId: AnyHandlerIdentifier) -> Node? {
        nodes.first { $0.exportedEndpoints.contains { $0.handlerId == handlerId } }
    }
}


extension DeployedSystem {
    /// A node within the deployed system
    public struct Node: Codable, Identifiable, Hashable, Equatable {
        /// ID of this node
        public let id: String
        /// exported handler ids
        public let exportedEndpoints: Set<ExportedEndpoint>
        /// Additional deployment provider specific data
        public private(set) var userInfo: Data?
        
        public init<T: Encodable>(id: String, exportedEndpoints: Set<ExportedEndpoint>, userInfo: T?, userInfoType: T.Type = T.self) throws {
            self.id = id
            self.exportedEndpoints = exportedEndpoints
            try setUserInfo(userInfo, type: T.self)
        }
        
        
        private mutating func setUserInfo<T: Encodable>(_ value: T?, type _: T.Type = T.self) throws {
            self.userInfo = try value.map { try $0.encodeToJSON() }
        }
        
        
        public func readUserInfo<T: Decodable>(as _: T.Type) -> T? {
            userInfo.flatMap { try? T(decodingJSON: $0) }
        }
        
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public static func == (lhs: Node, rhs: Node) -> Bool {
            lhs.id == rhs.id
        }
        
        
        public func withUserInfo<T: Encodable>(_ userInfo: T?) throws -> Self {
            var copy = self
            try copy.setUserInfo(userInfo, type: T.self)
            return copy
        }
        
        
        /// The deployment options for all endpoints exported by this node
        public func combinedEndpointDeploymentOptions() -> DeploymentOptions {
            DeploymentOptions(exportedEndpoints.map(\.deploymentOptions).flatMap(\.options))
        }
    }
}
