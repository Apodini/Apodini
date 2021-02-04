//
//  LambdaRuntime.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-18.
//

import Foundation
import Vapor
import ApodiniDeployRuntimeSupport
import DeploymentTargetAWSLambdaCommon
import VaporAWSLambdaRuntime


public class LambdaRuntime: DeploymentProviderRuntimeSupport {
    public static let deploymentProviderId = LambdaDeploymentProviderId
    
    private let deploymentStructure: DeployedSystemStructure
    private let lambdaDeploymentContext: LambdaDeployedSystemContext
    
    
    public required init(deployedSystemStructure: DeployedSystemStructure) throws {
        self.deploymentStructure = deployedSystemStructure
        guard let lambdaDeploymentContext = deploymentStructure.readUserInfo(as: LambdaDeployedSystemContext.self) else {
            throw NSError(domain: Self.deploymentProviderId.rawValue, code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Unable to read userInfo object"
            ])
        }
        self.lambdaDeploymentContext = lambdaDeploymentContext
    }
    
    
    public func configure(_ app: Vapor.Application) throws {
        print("-[\(Self.self) \(#function)] env", ProcessInfo.processInfo.environment)
        app.servers.use(.lambda)
        app.http.server.configuration.address = .hostname(lambdaDeploymentContext.apiGatewayHostname, port: 443)
    }
    
    
    public func handleRemoteHandlerInvocation<Response: Decodable>(
        withId handlerId: String,
        inTargetNode targetNode: DeployedSystemConfiguration.Node,
        responseType: Response.Type,
        parameters: [HandlerInvocationParameter]
    ) throws -> RemoteHandlerInvocationRequestResponse<Response> {
        return .invokeDefault(url: URL(string: "https://\(lambdaDeploymentContext.apiGatewayHostname)")!)
    }
}
