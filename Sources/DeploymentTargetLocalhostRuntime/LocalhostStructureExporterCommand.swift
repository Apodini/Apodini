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

/// The default `StructureExporter` of the localhost deployment provider. This command is responsible for
/// exporting the web service structure in a way that is understandable by the `LocalhostDeploymentProvider`.
/// These commands are added to Apodini by default.
/// The user should only added this command manually if he uses a custom `CommandConfiguration` in his web service.
/// The command needs to be added following this pattern for the providers to work:
///  `ApodiniDeployCommand.withSubcommands(
///         `ExportStructureCommand.withSubcommands(
///             `LocalhostStructureExporterCommand.self`,
///         `    ... any other exporter commands you want to use
///          `)`
///  `)`
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
    
    @OptionGroup
    public var webServiceWithArguments: Service
    
    public func run() throws {
        let app = Application()

        app.storage.set(DeploymentStructureExporterStorageKey.self, to: self)
        try webServiceWithArguments.start(mode: .startup, app: app)
    }
    
    public func retrieveStructure(
        _ endpoints: Set<CollectedEndpointInfo>,
        config: DeploymentConfig,
        app: Application
    ) throws -> AnyDeployedSystem {
        guard let openApiDocument = app.storage.get(OpenAPI.StorageKey.self)?.document else {
            throw ApodiniDeployRuntimeSupportError(message: "Unable to get OpenAPI document")
        }
        let defaultSystem = try self.retrieveDefaultDeployedSystem(endpoints, config: config, app: app)
        
        return LocalhostDeployedSystem(
            deploymentProviderId: DeploymentProviderID(self.identifier),
            nodes: Set(try defaultSystem.nodes.enumerated().map { idx, node in
                try node.withUserInfo(LocalhostLaunchInfo(port: self.endpointProcessesBasePort + idx))
            }),
            openApiDocument: openApiDocument
        )
    }
    
    public init() {}
}
