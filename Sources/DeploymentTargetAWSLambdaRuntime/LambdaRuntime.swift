//
//  LambdaRuntime.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-18.
//

import Foundation
import Vapor
import Apodini
import ApodiniDeployRuntimeSupport
import DeploymentTargetAWSLambdaCommon
import VaporAWSLambdaRuntime


public class LambdaRuntime: DeploymentProviderRuntimeSupport {
    public static let deploymentProviderId = LambdaDeploymentProviderId
    
    public let deployedSystem: DeployedSystemStructure
    public let currentNodeId: DeployedSystemStructure.Node.ID
    private let lambdaDeploymentContext: LambdaDeployedSystemContext
    
    public required init(deployedSystem: DeployedSystemStructure, currentNodeId: DeployedSystemStructure.Node.ID) throws {
        self.deployedSystem = deployedSystem
        self.currentNodeId = currentNodeId
        guard let lambdaDeploymentContext = deployedSystem.readUserInfo(as: LambdaDeployedSystemContext.self) else {
            throw NSError(domain: Self.deploymentProviderId.rawValue, code: 6667, userInfo: [
                NSLocalizedDescriptionKey: "Unable to read userInfo object" as NSString
            ])
        }
        self.lambdaDeploymentContext = lambdaDeploymentContext
    }
    
    
    public func configure(_ app: Apodini.Application) throws {
        print("-[\(Self.self) \(#function)] env", ProcessInfo.processInfo.environment)
        app.vapor.app.servers.use(.lambda)
        //app.vapor.app.http.server.configuration.address = .hostname(lambdaDeploymentContext.apiGatewayHostname, port: 443)
    }
    
    
    public func handleRemoteHandlerInvocation<H: IdentifiableHandler>(
        _ invocation: HandlerInvocation<H>
    ) throws -> RemoteHandlerInvocationRequestResponse<H.Response.Content> {
        .invokeDefault(url: URL(string: "https://\(lambdaDeploymentContext.apiGatewayHostname)")!)
    }
}
