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
import OpenAPIKit


public class LambdaRuntime<Service: WebService>: DeploymentProviderRuntime {
    public static var identifier: DeploymentProviderID {
        lambdaDeploymentProviderId
    }
    
    public let deployedSystem: AnyDeployedSystem
    public let currentNodeId: DeployedSystemNode.ID
    private let lambdaDeploymentContext: LambdaDeployedSystemContext
    
    public required init(deployedSystem: AnyDeployedSystem, currentNodeId: DeployedSystemNode.ID) throws {
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
    
    public static var exportCommand: StructureExporter.Type {
        LambdaStructureExporterCommand<Service>.self
    }
    
    public static var startupCommand: DeploymentStartupCommand.Type {
        LambdaStartupCommand<Service>.self
    }
}


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
    
    @ArgumentParser.Option(help: "The identifier of the deployment provider")
    public var identifier: String
    
    @ArgumentParser.Option(help: "Defines the AWS API Gateway ID that is used.")
    var awsApiGatewayApiId: String
    
    @ArgumentParser.Option
    var awsRegion: String = "eu-central-1"

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
        
        try Service.start(app: app, webService: Service())
    }
    
    public func retrieveStructure(
        _ endpoints: Set<CollectedEndpointInfo>,
        config: DeploymentConfig,
        app: Apodini.Application) throws -> AnyDeployedSystem {
        guard let openApiDocument = app.storage.get(OpenAPI.StorageKey.self)?.document else {
            throw ApodiniDeployRuntimeSupportError(message: "Unable to get OpenAPI document")
        }
        let defaultSystem = try self.retrieveDefaultDeployedSystem(endpoints, config: config, app: app)
        let awsSystem = try LambdaDeployedSystem(
            deploymentProviderId: DeploymentProviderID(rawValue: self.identifier),
            nodes: defaultSystem.nodes,
            userInfo: LambdaDeployedSystemContext(awsRegion: awsRegion, apiGatewayApiId: awsApiGatewayApiId),
            openApiDocument: openApiDocument
        )
        return awsSystem
    }
}

public struct LambdaStartupCommand<Service: WebService>: DeploymentStartupCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "aws",
            abstract: "Start a web service - AWS Lambda",
            discussion: "Starts up an Apodini web service for the aws lambda deployment",
            version: "0.0.1"
        )
    }

    @ArgumentParser.Argument(help: "The location of the json containing the system structure")
    public var filePath: String
    
    @ArgumentParser.Option(help: "The identifier of the deployment node")
    public var nodeId: String

    public var deployedSystem: AnyDeployedSystem.Type {
        LambdaDeployedSystem.self
    }
    
    public func run() throws {
        let app = Application()
        
        app.storage.set(DeploymentStartUpStorageKey.self, to: self)
        try Service.start(app: app, webService: Service())
    }

    public init() {}
}
