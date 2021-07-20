//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Vapor
import Apodini
import ApodiniVaporSupport
import ApodiniDeployRuntimeSupport
import DeploymentTargetAWSLambdaCommon
import VaporAWSLambdaRuntime


public class LambdaRuntime: DeploymentProviderRuntime {
    public static let identifier = lambdaDeploymentProviderId
    
    public let deployedSystem: DeployedSystem
    public let currentNodeId: DeployedSystem.Node.ID
    private let lambdaDeploymentContext: LambdaDeployedSystemContext
    
    public required init(deployedSystem: DeployedSystem, currentNodeId: DeployedSystem.Node.ID) throws {
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
}
