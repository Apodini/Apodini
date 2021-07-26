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

extension LocalhostRuntime {
    public static var exportCommand: ParsableCommand.Type {
        ExportWSLocalhostCommand<Service>.self
    }
}

public struct ExportWSLocalhostCommand<Service: WebService>: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "local",
                             abstract: "Export web service structure - Localhost",
                             discussion: """
                                    Exports an Apodini web service structure for localhost deployment
                                  """,
                             version: "0.0.1")
    }
    
    @OptionGroup
    var options: ExportStructureCommand.ExportOptions
    
    public init() {}
    
    public func run() throws {
        let localhostCoordinator = LocalhostStructureExporter(
            fileUrl: URL(fileURLWithPath: options.filePath),
            providerID: DeploymentProviderID(options.identifier)
        )
        DeploymentMemoryStorage.current.store(localhostCoordinator)
        var webService = Service.init()
        try webService.run()
    }
}

public struct LocalhostStructureExporter: StructureExporter {
    public var providerID: DeploymentProviderID
    public var fileUrl: URL
    
    public init(fileUrl: URL, providerID: DeploymentProviderID) {
        self.providerID = providerID
        self.fileUrl = fileUrl
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
        return defaultSystem
    }
}
