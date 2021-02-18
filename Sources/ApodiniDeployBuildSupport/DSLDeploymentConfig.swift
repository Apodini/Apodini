//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-07.
//


import Foundation
import Runtime
import Apodini



extension NSError {
    public static func apodiniDeploy(code: Int = 0, localizedDescription: String) -> NSError {
        return NSError(domain: "ApodiniDeploy", code: code, userInfo: [
            NSLocalizedDescriptionKey: localizedDescription
        ])
    }
}




public struct HandlerTypeIdentifier: Codable, Hashable, Equatable {
    private let rawValue: String
    
    public init<H: Handler>(_: H.Type) {
        self.rawValue = "\(H.self)"
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






// TODO rename to smth like DeploymentGroupInput? this isn't the actual deployment group, just the input collected from the user, which will later be used to create the proper deployment group
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
    
    public static func generateGroupId() -> ID {
        UUID().uuidString
    }
}


public struct DeploymentGroupsConfig: Codable {
    public enum DefaultGrouping: Int, Codable { // the cases here need better names
        /// Every handler which is not explicitly put in a group will get its own group
        case separateNodes
        /// All handlers which are not explicitly put into a group will be put into a single group
        case singleNode
    }
    public let defaultGrouping: DefaultGrouping
    public let groups: Set<DeploymentGroup>
    
    public init(defaultGrouping: DefaultGrouping = .separateNodes, groups: Set<DeploymentGroup> = []) {
        self.defaultGrouping = defaultGrouping
        self.groups = groups
    }
}



public struct DeploymentConfig: Codable {
    public let deploymentGroups: DeploymentGroupsConfig
    
    public init(deploymentGroups: DeploymentGroupsConfig = .init()) {
        self.deploymentGroups = deploymentGroups
    }
}
