//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Vapor
import ArgumentParser
import Apodini
import ApodiniVaporSupport
import ApodiniDeployRuntimeSupport
import DeploymentTargetAWSLambdaCommon
import VaporAWSLambdaRuntime
import ApodiniOpenAPI


public class LambdaRuntime<Service: WebService>: DeploymentProviderRuntime {
    public static var identifier: DeploymentProviderID {
        lambdaDeploymentProviderId
    }
    
    public let deployedSystem: DeployedSystem
    public let currentNodeId: DeployedSystemNode.ID
    private let lambdaDeploymentContext: LambdaDeployedSystemContext
    
    public required init(deployedSystem: DeployedSystem, currentNodeId: DeployedSystemNode.ID) throws {
        self.deployedSystem = deployedSystem
        self.currentNodeId = currentNodeId
        guard let lambdaDeploymentContext = deployedSystem.readUserInfo(as: LambdaDeployedSystemContext.self) else {
            throw ApodiniDeployRuntimeSupportError(
                deploymentProviderId: Self.identifier,
                message: "Unable to read userInfo"
            )
        }
        self.lambdaDeploymentContext = lambdaDeploymentContext
    }
    
    
    public func configure(_ app: Apodini.Application) throws {
        print("-[\(Self.self) \(#function)] env", ProcessInfo.processInfo.environment)
        app.vapor.app.servers.use(.lambda)
    }
    
    
    public func handleRemoteHandlerInvocation<H: IdentifiableHandler>(
        _ invocation: HandlerInvocation<H>
    ) throws -> RemoteHandlerInvocationRequestResponse<H.Response.Content> {
        guard let url = URL(string: "https://\(lambdaDeploymentContext.apiGatewayHostname)") else {
            throw ApodiniDeployRuntimeSupportError(
                deploymentProviderId: Self.identifier,
                message: "Unable to construct target url"
            )
        }
        return .invokeDefault(url: url)
    }
    
    public static var exportCommand: ParsableCommand.Type {
        LambdaExportStructureCommand<Service>.self
    }
}

public struct LambdaExportStructureCommand<Service: WebService>: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "aws",
                             abstract: "Export web service structure - AWS",
                             discussion: """
                                    Exports an Apodini web service structure for localhost deployment
                                  """,
                             version: "0.0.1")
    }
    
    @OptionGroup
    var options: ExportStructureCommand.ExportOptions
    
    @ArgumentParser.Option(help: "Defines the AWS API Gateway ID that is used. If '_createNew' is passed in the deployment provider creates a new AWS API Gateway")
    var awsApiGatewayApiId: String
    
    @ArgumentParser.Option
    var awsRegion: String = "eu-central-1"
    
    public init() {}
    
    public func run() throws {
        let lambdaStructureExporter = LambdaStructureExporter(
            providerID: DeploymentProviderID(options.identifier),
            fileUrl: URL(fileURLWithPath: options.filePath),
            awsApiGatewayApiId: awsApiGatewayApiId,
            awsRegion: awsRegion)
        
        DeploymentMemoryStorage.current.store(lambdaStructureExporter)
        var webService = Service.init()
        try webService.run()
    }
}

public struct LambdaStructureExporter: StructureExporter {
    public var providerID: DeploymentProviderID
    public var fileUrl: URL
    
    public let awsApiGatewayApiId: String
    public let awsRegion: String
    
    public init(providerID: DeploymentProviderID,
                fileUrl: URL,
                awsApiGatewayApiId: String,
                awsRegion: String) {
        self.providerID = providerID
        self.fileUrl = fileUrl
        self.awsApiGatewayApiId = awsApiGatewayApiId
        self.awsRegion = awsRegion
    }
    
    public var nodeIdProvider: (Set<CollectedEndpointInfo>) -> String {
        { endpoints in
            guard let endpoint = endpoints.first, endpoints.count == 1 else {
                return UUID().uuidString
            }
            return endpoint.endpoint[AnyHandlerIdentifier.self].rawValue.replacingOccurrences(of: ".", with: "-")
        }
    }
    
    public func retrieveStructure(_ endpoints: Set<CollectedEndpointInfo>, config: DeploymentConfig, app: Apodini.Application) throws -> AnyDeployedSystem {
        guard let openApiDocument = app.storage.get(OpenAPI.StorageKey.self)?.document else {
            throw ApodiniDeployRuntimeSupportError(message: "Unable to get OpenAPI document")
        }
        let defaultSystem = try self.retrieveDefaultDeployedSystem(endpoints, config: config, app: app)
        let awsSystem = try LambdaDeployedSystem(deploymentProviderId: self.providerID, nodes: defaultSystem.nodes, userInfo: LambdaDeployedSystemContext(awsRegion: awsRegion, apiGatewayApiId: awsApiGatewayApiId), openApiDocument: openApiDocument)
        return awsSystem
    }
}
