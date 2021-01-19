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
    
    public required init(systemConfig: DeployedSystemConfiguration) {
        // TODO
    }
    
    public func configure(_ app: Vapor.Application) throws {
        app.servers.use(.lambda)
        app.http.server.configuration.address = .hostname("https://nwks9298sb.execute-api.eu-central-1.amazonaws.com", port: 443)
    }
    
    public func invokeRemoteHandler<Response : Decodable>(
        withId handlerId: String,
        inTargetNode targetNode: DeployedSystemConfiguration.Node,
        responseType: Response.Type,
        parameters: [HandlerInvocationParameter]
    ) throws -> EventLoopFuture<Response> {
        throw NSError(domain: "ugh", code: 0, userInfo: nil)
    }
}
