//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ArgumentParser
import Apodini
import ApodiniDeployerRuntimeSupport
import AWSLambdaDeploymentProviderCommon
import ApodiniOpenAPI
import OpenAPIKit

/// The default `StructureExporter` of the localhost Deployment Provider. This command is responsible for
/// exporting the web service structure in a way that is understandable by the `LambdaDeploymentProvider`.
/// These commands are added to Apodini by default.
/// The user should only added this command manually if he uses a custom `CommandConfiguration` in his web service.
/// The command needs to be added following this pattern for the providers to work:
///  `ApodiniDeployerCommand.withSubcommands(
///         `ExportStructureCommand.withSubcommands(
///             `LambdaStructureExporterCommand.self`,
///         `    ... any other exporter commands you want to use
///          `)`
///  `)`
public struct LambdaStructureExporterCommand<Service: WebService>: StructureExporter {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "aws",
            abstract: "Export web service structure - AWS",
            discussion: "Exports an Apodini web service structure for localhost deployment",
            version: "0.0.1"
        )
    }
    
    @ArgumentParser.Argument(help: "The location of the json file")
    public var filePath: String
    
    @ArgumentParser.Option(help: "The identifier of the Deployment Provider")
    public var identifier: String
    
    @ArgumentParser.Option(help: "Defines the AWS API Gateway ID that is used.")
    var awsApiGatewayApiId: String
    
    @ArgumentParser.Option
    var awsRegion: String = "eu-central-1"
    
    @ArgumentParser.OptionGroup
    var webServiceWithArguments: Service

    public init() {}
    
    public var nodeIdProvider: (Set<CollectedEndpointInfo>) -> String {
        { endpoints in
            guard let endpoint = endpoints.first, endpoints.count == 1 else {
                return UUID().uuidString
            }
            return endpoint.endpoint[AnyHandlerIdentifier.self].rawValue.replacingOccurrences(of: ".", with: "-")
        }
    }
    
    public func run() throws {
        let app = Apodini.Application()
        app.storage.set(DeploymentStructureExporterStorageKey.self, to: self)
        
        try webServiceWithArguments.start(mode: .startup, app: app)
    }
    
    public func retrieveStructure(
        _ endpoints: Set<CollectedEndpointInfo>,
        config: DeploymentConfig,
        app: Apodini.Application) throws -> AnyDeployedSystem {
        guard let openApiDocument = app.storage.get(OpenAPI.StorageKey.self)?.document else {
            throw ApodiniDeployerRuntimeSupportError(message: "Unable to get OpenAPI document")
        }
        let defaultSystem = try self.retrieveDefaultDeployedSystem(endpoints, config: config, app: app)
        let awsSystem = try LambdaDeployedSystem(
            deploymentProviderId: DeploymentProviderID(rawValue: self.identifier),
            nodes: defaultSystem.nodes,
            context: LambdaDeployedSystemContext(awsRegion: awsRegion, apiGatewayApiId: awsApiGatewayApiId, for: endpoints),
            openApiDocument: openApiDocument
        )
        return awsSystem
    }
}
