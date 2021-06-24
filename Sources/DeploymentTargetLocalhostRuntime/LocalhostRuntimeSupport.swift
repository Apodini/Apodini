//
//  LocalhostRuntimeSupport.swift
//
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
import Apodini
import ApodiniDeployRuntimeSupport
import DeploymentTargetLocalhostCommon


public class LocalhostRuntime: DeploymentProviderRuntime {
    public static let identifier = localhostDeploymentProviderId
    
    public let deployedSystem: DeployedSystem
    public let currentNodeId: DeployedSystem.Node.ID
    private let currentNodeCustomLaunchInfo: LocalhostLaunchInfo
    
    public required init(deployedSystem: DeployedSystem, currentNodeId: DeployedSystem.Node.ID) throws {
        self.deployedSystem = deployedSystem
        self.currentNodeId = currentNodeId
        guard
            let node = deployedSystem.node(withId: currentNodeId),
            let launchInfo = node.readUserInfo(as: LocalhostLaunchInfo.self)
        else {
            throw ApodiniDeployRuntimeSupportError(
                deploymentProviderId: Self.identifier,
                message: "Unable to read userInfo"
            )
        }
        self.currentNodeCustomLaunchInfo = launchInfo
    }
    
    public func configure(_ app: Apodini.Application) throws {
        app.http.address = .hostname(nil, port: currentNodeCustomLaunchInfo.port)
    }
    
    public func handleRemoteHandlerInvocation<H: IdentifiableHandler>(
        _ invocation: HandlerInvocation<H>
    ) throws -> RemoteHandlerInvocationRequestResponse<H.Response.Content> {
        guard
            let LLI = invocation.targetNode.readUserInfo(as: LocalhostLaunchInfo.self),
            let url = URL(string: "http://127.0.0.1:\(LLI.port)")
        else {
            throw ApodiniDeployRuntimeSupportError(
                deploymentProviderId: identifier,
                message: "Unable to read port and construct url"
            )
        }
        return .invokeDefault(url: url)
    }
}
