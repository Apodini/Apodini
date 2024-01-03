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


extension WebService {
    /// The AWS Lambda Deployment Provider allows partitioning an Apodini web services into multiple AWS Lambda functions
    public typealias AWSLambda = LambdaRuntime<Self>
}


public class LambdaRuntime<Service: WebService>: DeploymentProviderRuntime {
    public static var identifier: DeploymentProviderID {
        lambdaDeploymentProviderId
    }
    
    public let deployedSystem: any AnyDeployedSystem
    public let currentNodeId: DeployedSystemNode.ID
    private let lambdaDeploymentContext: LambdaDeployedSystemContext
    
    public required init(deployedSystem: any AnyDeployedSystem, currentNodeId: DeployedSystemNode.ID) throws {
        self.deployedSystem = deployedSystem
        self.currentNodeId = currentNodeId
        guard let lambdaDeploymentContext = (deployedSystem as? LambdaDeployedSystem)?.context else {
            throw ApodiniDeployerRuntimeSupportError(
                deploymentProviderId: Self.identifier,
                message: "Unable to find '\(LambdaDeployedSystem.self)'"
            )
        }
        self.lambdaDeploymentContext = lambdaDeploymentContext
    }
    
    
    public func configure(_ app: Apodini.Application) throws {
        app.httpServer.shouldBindOnStart = false
        app.lifecycle.use(LambdaServer(application: app))
    }
    
    
    public func handleRemoteHandlerInvocation<H: IdentifiableHandler>(
        _ invocation: HandlerInvocation<H>
    ) throws -> RemoteHandlerInvocationRequestResponse<H.Response.Content> {
        guard let url = URL(string: "https://\(lambdaDeploymentContext.apiGatewayHostname)") else {
            throw ApodiniDeployerRuntimeSupportError(
                deploymentProviderId: Self.identifier,
                message: "Unable to construct target url"
            )
        }
        return .invokeDefault(url: url)
    }
    
    public static var exportCommand: any StructureExporter.Type {
        LambdaStructureExporterCommand<Service>.self
    }
    
    public static var startupCommand: any DeploymentStartupCommand.Type {
        LambdaStartupCommand<Service>.self
    }
}
