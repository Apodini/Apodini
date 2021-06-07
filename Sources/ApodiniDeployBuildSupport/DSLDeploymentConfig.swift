//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-07.
//


import Foundation
import Runtime
import Apodini


public struct HandlerTypeIdentifier: Codable, Hashable, Equatable {
    private let rawValue: String
    
    public init<H: Handler>(_: H.Type) {
        self.rawValue = "\(H.self)"
    }
    
    internal init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
    
    public static func == <H: Handler> (lhs: HandlerTypeIdentifier, rhs: H.Type) -> Bool {
        lhs == HandlerTypeIdentifier(rhs)
    }
    
    public static func == <H: Handler> (lhs: H.Type, rhs: HandlerTypeIdentifier) -> Bool {
        HandlerTypeIdentifier(lhs) == rhs
    }
}


public struct DeploymentGroup: Codable, Hashable, Equatable {
    public typealias ID = String
    
    public let id: ID
    public let handlerTypes: Set<HandlerTypeIdentifier>
    public let handlerIds: Set<AnyHandlerIdentifier>
    
    public init(id: ID? = nil, handlerTypes: Set<HandlerTypeIdentifier>, handlerIds: Set<AnyHandlerIdentifier>) {
        self.id = id ?? Self.generateGroupId()
        self.handlerTypes = handlerTypes
        self.handlerIds = handlerIds
    }
    
    /// Utility function for generating default group ids
    public static func generateGroupId() -> ID {
        UUID().uuidString
    }
}


public struct DeploymentConfig: Codable, Equatable {
    public enum DefaultGrouping: Int, Codable, Equatable {
        /// Every handler which is not explicitly put in a group will get its own group
        case separateNodes
        /// All handlers which are not explicitly put into a group will be put into a single group
        case singleNode
    }
    public let defaultGrouping: DefaultGrouping
    public let deploymentGroups: Set<DeploymentGroup>
    
    public init(defaultGrouping: DefaultGrouping = .separateNodes,
                deploymentGroups: Set<DeploymentGroup> = []) {
        self.defaultGrouping = defaultGrouping
        self.deploymentGroups = deploymentGroups
    }
}
