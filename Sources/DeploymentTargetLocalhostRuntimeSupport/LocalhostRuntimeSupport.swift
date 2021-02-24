//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
import Apodini
import ApodiniDeployRuntimeSupport
import DeploymentTargetLocalhostCommon


public class LocalhostRuntimeSupport: DeploymentProviderRuntimeSupport {
    public static let deploymentProviderId = LocalhostDeploymentProviderId
    
    public let deployedSystem: DeployedSystem
    public let currentNodeId: DeployedSystem.Node.ID
    private let currentNodeCustomLaunchInfo: LocalhostLaunchInfo
    
    
    public required init(deployedSystem: DeployedSystem, currentNodeId: DeployedSystem.Node.ID) {
        self.deployedSystem = deployedSystem
        self.currentNodeId = currentNodeId
        self.currentNodeCustomLaunchInfo = deployedSystem.node(withId: currentNodeId)!.readUserInfo(as: LocalhostLaunchInfo.self)!
    }
    
    
    public func configure(_ app: Apodini.Application) throws {
        app.http.address = .hostname(nil, port: currentNodeCustomLaunchInfo.port)
        //app.vapor.app.http.server.configuration.port = currentNodeCustomLaunchInfo.port
    }
    
    
    public func handleRemoteHandlerInvocation<H: IdentifiableHandler>(
        _ invocation: HandlerInvocation<H>
    ) throws -> RemoteHandlerInvocationRequestResponse<H.Response.Content> {
        let LLI = invocation.targetNode.readUserInfo(as: LocalhostLaunchInfo.self)!
        // TODO read hostname from app?
        return .invokeDefault(url: URL(string: "http://127.0.0.1:\(LLI.port)")!)
    }
}
