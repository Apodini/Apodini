//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation


// TODO rename file



// was intended as a Codable-conformant NSNull implemnentation. can we get rid of this?
public struct Null: Codable {
    public init() {}
    
    public init(from decoder: Decoder) throws {
        let wasNil = try decoder.singleValueContainer().decodeNil()
        if !wasNil {
            throw NSError(domain: "Apodini", code: 0, userInfo: [NSLocalizedDescriptionKey: "wasnt nil"])
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}




public typealias DeployedSystemConfiguration = DeployedSystemStructure


/// The structure of a deployed system.
/// A deployed system is a distributed system consisting of one or more nodes.
/// Each node implements one or more of the deployed `WebService`'s endpoints.
/// - Note: There may be more than one instances of a node running at a given time,
///   for example when deploying to a platform which supports scaling.
public struct DeployedSystemStructure: Codable {
    /// Identifier of the deployment provider used to create the deployment
    public let deploymentProviderId: DeploymentProviderID
    
    /// Identifier of the node the instance being launched represents
    public private(set) var currentInstanceNodeId: Node.ID
    
    /// The nodes the system consists of
    public let nodes: [Node]
    
    /// Additional, deployment provider specific data
    public let userInfo: Data
    
    
    public init<T: Encodable>(
        deploymentProviderId: DeploymentProviderID,
        currentInstanceNodeId: Node.ID,
        nodes: [Node],
        userInfo: T?,
        userInfoType: T.Type = T.self
    ) throws {
        self.deploymentProviderId = deploymentProviderId
        self.currentInstanceNodeId = currentInstanceNodeId
        self.nodes = nodes
        self.userInfo = try JSONEncoder().encode(userInfo)
        
        precondition(nodes.contains(where: { $0.id == currentInstanceNodeId }))
    }
    
    
    public init(contentsOf url: URL, options: Data.ReadingOptions = []) throws {
        let data = try Data(contentsOf: url, options: options)
        self = try JSONDecoder().decode(Self.self, from: data)
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
    
    public func withCurrentInstanceNodeId(_ newId: Node.ID) -> Self {
        var copy = self
        copy.currentInstanceNodeId = newId
        return copy
        
    }
}


extension DeployedSystemConfiguration {
    /// The current instance's node within the system
    public var currentInstanceNode: Node {
        node(withId: currentInstanceNodeId)!
    }
    
    public func node(withId nodeId: Node.ID) -> Node? {
        nodes.first { $0.id == nodeId }
    }
    
    public func nodesExportingEndpoint(withHandlerId handlerId: String) -> Set<Node> {
        let nodes = self.nodes.filter { $0.exportedEndpoints.contains { $0.handlerIdRawValue == handlerId } }
        return Set(nodes)
    }
    
    /// Returns a random node exporting an endpoint with the specified handler identifier.
    public func randomNodeExportingEndpoint(withHandlerId handlerId: String) -> Node? { // TODO rename from random once we enforce non-duplicate endpoint-node mappings
        return nodesExportingEndpoint(withHandlerId: handlerId).randomElement()
    }
}





extension DeployedSystemConfiguration {
    /// A node within the deployed system
    public struct Node: Codable, Identifiable, Hashable, Equatable {
        /// ID of this node
        public let id: String
        
        /// exported handler ids
        public let exportedEndpoints: [ExportedEndpoint]
        
        /// Additional deployment provider specific data
        public private(set) var userInfo: Data?
        
        public init<T: Encodable>(id: String, exportedEndpoints: [ExportedEndpoint], userInfo: T?, userInfoType: T.Type = T.self) throws {
            self.id = id
            self.exportedEndpoints = exportedEndpoints
            //self.userInfo = try userInfo.map { try JSONEncoder().encode($0) }
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
        
        
        //public func withUserInfo(_ userInfo: _OptionalNilComparisonType) -> Self {
            // ?? We can afford the try! here because we're passing nil, meaning that it'll never encode anything, meaning it won't crash ??
            //return try! Node(id: self.id, exportedEndpoints: self.exportedEndpoints, userInfo: nil, userInfoType: Null.self)
        //}
    }
}
