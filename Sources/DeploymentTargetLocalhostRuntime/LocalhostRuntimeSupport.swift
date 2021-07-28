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
    
    public static var exportCommand: ParsableCommand.Type {
        ExportWSLocalhostCommand<Service>.self
    }
    
    public static var startupCommand: ParsableCommand.Type {
        LocalhostStartupCommand<Service>.self
    }
}

public struct ExportWSLocalhostCommand<Service: WebService>: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "local",
                             abstract: "Export web service structure - Localhost",
                             discussion: """
                                    Exports an Apodini web service structure for the localhost deployment
                                  """,
                             version: "0.0.1")
    }
    
    @OptionGroup
    var options: ExportStructureCommand.ExportOptions
    
    @Option(help: "The port number for the first-launched child process")
    var endpointProcessesBasePort: Int = 5000
    
    public init() {}
    
    public func run() throws {
        let app = Application()
        
        let localhostCoordinator = LocalhostStructureExporter(
            fileUrl: URL(fileURLWithPath: options.filePath),
            providerID: DeploymentProviderID(options.identifier),
            endpointProcessesBasePort: self.endpointProcessesBasePort
        )
        
        app.storage.set(DeploymentStructureExporterStorageKey.self, to: localhostCoordinator)
        try Service.start(app: app, webService: Service())
    }
}

public struct LocalhostStructureExporter: StructureExporter {
    public var providerID: DeploymentProviderID
    public var fileUrl: URL
    
    public var endpointProcessesBasePort: Int
    
    public init(fileUrl: URL, providerID: DeploymentProviderID, endpointProcessesBasePort: Int) {
        self.providerID = providerID
        self.fileUrl = fileUrl
        self.endpointProcessesBasePort = endpointProcessesBasePort
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
}

public struct LocalhostStartupCommand<Service: WebService>: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "local",
                             abstract: "Start a web service - Localhost",
                             discussion: """
                                    Starts up an Apodini web service for the localhost deployment
                                  """,
                             version: "0.0.1")
    }
    
    @OptionGroup
    var commonOptions: StartupCommand.CommonOptions
    
    public func run() throws {
        let app = Application()
        let defaultConfig = StartupCommand.DefaultDeploymentStartupConfiguration(
            URL(fileURLWithPath: commonOptions.fileUrl),
            nodeId: commonOptions.nodeId
        )
        app.storage.set(DeploymentStartUpStorageKey.self, to: defaultConfig)
        try Service.start(app: app, webService: Service())
    }
    
    public init() {}
}
