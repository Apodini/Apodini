//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
import ApodiniDeployRuntimeSupport
import Vapor
import DeploymentTargetLocalhostCommon


public class LocalhostRuntimeSupport: DeploymentProviderRuntimeSupport {
    public static let deploymentProviderId = LocalhostDeploymentProviderId
    
    public let deployedSystem: DeployedSystemStructure
    public let currentNodeId: DeployedSystemStructure.Node.ID
    private let currentNodeCustomLaunchInfo: LocalhostLaunchInfo
    
    
    public required init(deployedSystem: DeployedSystemStructure, currentNodeId: DeployedSystemStructure.Node.ID) {
        self.deployedSystem = deployedSystem
        self.currentNodeId = currentNodeId
        self.currentNodeCustomLaunchInfo = deployedSystem.node(withId: currentNodeId)!.readUserInfo(as: LocalhostLaunchInfo.self)!
    }
    
    
    public func configure(_ app: Vapor.Application) throws {
        app.http.server.configuration.port = currentNodeCustomLaunchInfo.port
    }
    
    
    public func handleRemoteHandlerInvocation<Response: Decodable>(
        withId handlerId: String,
        inTargetNode targetNode: DeployedSystemStructure.Node,
        responseType: Response.Type,
        parameters: [HandlerInvocationParameter]
    ) throws -> RemoteHandlerInvocationRequestResponse<Response> {
        let LLI = targetNode.readUserInfo(as: LocalhostLaunchInfo.self)!
        return .invokeDefault(url: URL(string: "http://127.0.0.1:\(LLI.port)")!)
    }
}
