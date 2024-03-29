//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniDeployerRuntimeSupport
import LocalhostDeploymentProviderCommon
import ArgumentParser
import ApodiniOpenAPI


extension WebService {
    /// The Localhost Deployment Provider allows partitioning an Apodini web services in multiple subprocesses
    public typealias Localhost = LocalhostRuntime<Self>
}


public class LocalhostRuntime<Service: WebService>: DeploymentProviderRuntime {
    public static var identifier: DeploymentProviderID {
        localhostDeploymentProviderId
    }
    
    public let deployedSystem: AnyDeployedSystem
    public let currentNodeId: DeployedSystemNode.ID
    private let currentNodeCustomLaunchInfo: LocalhostLaunchInfo
    
    public required init(deployedSystem: AnyDeployedSystem, currentNodeId: DeployedSystemNode.ID) throws {
        self.deployedSystem = deployedSystem
        self.currentNodeId = currentNodeId
        guard
            let node = deployedSystem.node(withId: currentNodeId),
            let launchInfo = node.readUserInfo(as: LocalhostLaunchInfo.self)
        else {
            throw ApodiniDeployerRuntimeSupportError(
                deploymentProviderId: Self.identifier,
                message: "Unable to read userInfo"
            )
        }
        self.currentNodeCustomLaunchInfo = launchInfo
    }
    
    public func configure(_ app: Apodini.Application) throws {
        app.storage[HTTPConfigurationStorageKey.self] = HTTPConfiguration(
            bindAddress: .interface(HTTPConfiguration.Defaults.bindAddress, port: currentNodeCustomLaunchInfo.port)
        )
    }
    
    public func handleRemoteHandlerInvocation<H: IdentifiableHandler>(
        _ invocation: HandlerInvocation<H>
    ) throws -> RemoteHandlerInvocationRequestResponse<H.Response.Content> {
        guard
            let LLI = invocation.targetNode.readUserInfo(as: LocalhostLaunchInfo.self),
            let url = URL(string: "http://localhost:\(LLI.port)")
        else {
            throw ApodiniDeployerRuntimeSupportError(
                deploymentProviderId: identifier,
                message: "Unable to read port and construct url"
            )
        }
        return .invokeDefault(url: url)
    }
    
    public static var exportCommand: StructureExporter.Type {
        LocalhostStructureExporterCommand<Service>.self
    }
    
    public static var startupCommand: DeploymentStartupCommand.Type {
        LocalhostStartupCommand<Service>.self
    }
}
