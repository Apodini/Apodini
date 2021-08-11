//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniDeployRuntimeSupport
import DeploymentTargetLocalhostCommon
import ArgumentParser
import ApodiniOpenAPI


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
    
    public static var exportCommand: StructureExporter.Type {
        LocalhostStructureExporterCommand<Service>.self
    }
    
    public static var startupCommand: DeploymentStartupCommand.Type {
        LocalhostStartupCommand<Service>.self
    }
}

public struct LocalhostStructureExporterCommand<Service: WebService>: StructureExporter {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "local",
            abstract: "Export web service structure - Localhost",
            discussion: "Exports an Apodini web service structure for the localhost deployment",
            version: "0.3.0"
        )
    }
    
    @Argument(help: "The location of the json file")
    public var filePath: String
    
    @Option(help: "The identifier of the deployment provider")
    public var identifier: String
    
    @Option(help: "The port number for the first-launched child process")
    public var endpointProcessesBasePort: Int
    
    public func run() throws {
        let app = Application()

        app.storage.set(DeploymentStructureExporterStorageKey.self, to: self)
        try Service.start(app: app, webService: Service())
    }
    
    public func retrieveStructure(
        _ endpoints: Set<CollectedEndpointInfo>,
        config: DeploymentConfig,
        app: Application
    ) throws -> AnyDeployedSystem {
        guard let openApiDocument = app.storage.get(OpenAPI.StorageKey.self)?.document else {
            throw ApodiniDeployRuntimeSupportError(message: "Unable to get OpenAPI document")
        }
        
        var defaultSystem = try self.retrieveDefaultDeployedSystem(endpoints, config: config, app: app)
        
        defaultSystem.userInfo = try openApiDocument.encodeToJSON()
        defaultSystem.nodes = Set(try defaultSystem.nodes.enumerated().map { idx, node in
            try node.withUserInfo(LocalhostLaunchInfo(port: self.endpointProcessesBasePort + idx))
        })

        return defaultSystem
    }
    
    public init() {}
}

public struct LocalhostStartupCommand<Service: WebService>: DeploymentStartupCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "local",
            abstract: "Start a web service - Localhost",
            discussion: "Starts up an Apodini web service for the localhost deployment",
            version: "0.3.0"
        )
    }
    
    @Argument(help: "The location of the json containing the system structure")
    public var filePath: String
    
    @Option(help: "The identifier of the deployment node")
    public var nodeId: String
    
    public func run() throws {
        let app = Application()

        app.storage.set(DeploymentStartUpStorageKey.self, to: self)
        try Service.start(app: app, webService: Service())
    }
    
    public init() {}
}
