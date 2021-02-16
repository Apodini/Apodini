//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
import Apodini


// TODO rename file





/// The structure of a deployed system.
/// A deployed system is a distributed system consisting of one or more nodes.
/// Each node implements one or more of the deployed `WebService`'s endpoints.
/// - Note: There may be more than one instances of a node running at a given time,
///   for example when deploying to a platform which supports scaling.
public struct DeployedSystemStructure: Codable { // TODO or just `DeployedSystem`?
    /// Identifier of the deployment provider used to create the deployment
    public let deploymentProviderId: DeploymentProviderID
    
    /// The nodes the system consists of
    public let nodes: Set<Node>
    
    /// Additional, deployment provider specific data
    public let userInfo: Data
    
    
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
    
    
    public init(contentsOf url: URL, options: Data.ReadingOptions = []) throws {
        let data = try Data(contentsOf: url, options: options)
        self = try JSONDecoder().decode(Self.self, from: data)
        try nodes.assertHandlersLimitedToSingleNode()
    }
    
    
    public func writeTo(url: URL, options: Data.WritingOptions = []) throws {
        let encoder = JSONEncoder()
        #if DEBUG
        encoder.outputFormatting.insert(.prettyPrinted)
        #endif
        let data = try encoder.encode(self)
        try data.write(to: url, options: options)
    }
    
    
    public func readUserInfo<T: Decodable>(as _: T.Type) -> T? {
        return try? JSONDecoder().decode(T.self, from: userInfo)
    }
}


extension DeployedSystemStructure {
    public func node(withId nodeId: Node.ID) -> Node? {
        nodes.first { $0.id == nodeId }
    }
    
    public func nodeExportingEndpoint(withHandlerId handlerId: AnyHandlerIdentifier) -> Node? {
        nodes.first { $0.exportedEndpoints.contains { $0.handlerId == handlerId } }
    }
}





extension DeployedSystemStructure {
    /// A node within the deployed system
    public struct Node: Codable, Identifiable, Hashable, Equatable {
        /// ID of this node
        public let id: String
        
        /// exported handler ids
        public let exportedEndpoints: Set<ExportedEndpoint>
        
//        /// the merged deployment options of all endpoints in the node
//        public let deploymentOptions: XCollectedHandlerOptions
        
        /// Additional deployment provider specific data
        public private(set) var userInfo: Data?
        
        public init<T: Encodable>(id: String, exportedEndpoints: Set<ExportedEndpoint>, userInfo: T?, userInfoType: T.Type = T.self) throws {
            self.id = id
            self.exportedEndpoints = exportedEndpoints
            try setUserInfo(userInfo, type: T.self)
        }
        
        
        private mutating func setUserInfo<T: Encodable>(_ value: T?, type _: T.Type = T.self) throws {
            self.userInfo = try value.map { try JSONEncoder().encode($0) }
        }
        
        
        public func readUserInfo<T: Decodable>(as _: T.Type) -> T? {
            guard let data = userInfo else {
                return nil
            }
            return try? JSONDecoder().decode(T.self, from: data)
        }
        
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        public static func == (lhs: Node, rhs: Node) -> Bool {
            return lhs.id == rhs.id
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
        
        
        //public func withUserInfo(_ userInfo: _OptionalNilComparisonType) -> Self {
            // ?? We can afford the try! here because we're passing nil, meaning that it'll never encode anything, meaning it won't crash ??
            //return try! Node(id: self.id, exportedEndpoints: self.exportedEndpoints, userInfo: nil, userInfoType: Null.self)
        //}
    }
}
