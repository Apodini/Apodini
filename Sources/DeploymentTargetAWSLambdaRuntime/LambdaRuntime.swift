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
        guard let lambdaDeploymentContext = (deployedSystem as? LambdaDeployedSystem)?.context else {
            throw ApodiniDeployRuntimeSupportError(
                deploymentProviderId: Self.identifier,
                message: "Unable to find '\(LambdaDeployedSystem.self)'"
            )
        }
        self.lambdaDeploymentContext = lambdaDeploymentContext
    }
    
    
    public func configure(_ app: Apodini.Application) throws {
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
