//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import ApodiniDeployerBuildSupport
import OpenAPIKit


/// Identifier of the lambda Deployment Provider.
public let lambdaDeploymentProviderId = DeploymentProviderID("apodini.ApodiniDeploymentProvider.AWSLambda")


// the DeployedSystem user info for lambda deployments
public struct LambdaDeployedSystemContext: Codable {
    public let awsRegion: String
    public let apiGatewayApiId: String

    public let memoryMaximum: Int
    public let timeoutMaximum: Int
    
    public init(awsRegion: String, apiGatewayApiId: String, for endpoints: Set<CollectedEndpointInfo>) {
        self.awsRegion = awsRegion
        self.apiGatewayApiId = apiGatewayApiId

        let reducedOptions = endpoints.map(\.deploymentOptions).reduceIntoFirst { optionSet, value in
            optionSet.merge(withRHS: value)
        } ?? .init()

        self.memoryMaximum = Int(reducedOptions.option(for: .memorySize).rawValue)
        self.timeoutMaximum = Int(reducedOptions.option(for: .timeoutValue).rawValue)
    }
}

extension LambdaDeployedSystemContext {
    /// The hostname of this Lambda's API Gateway
    public var apiGatewayHostname: String {
        "\(apiGatewayApiId).execute-api.\(awsRegion).amazonaws.com"
    }
}


public struct LambdaDeployedSystem: AnyDeployedSystem {
    public var nodes: Set<DeployedSystemNode>
    
    public var deploymentProviderId: DeploymentProviderID
    
    public var openApiDocument: OpenAPI.Document
    
    public var context: LambdaDeployedSystemContext
    
    public init(
        deploymentProviderId: DeploymentProviderID,
        nodes: Set<DeployedSystemNode>,
        context: LambdaDeployedSystemContext,
        openApiDocument: OpenAPI.Document
    ) throws {
        self.deploymentProviderId = deploymentProviderId
        self.nodes = nodes
        self.context = context
        self.openApiDocument = openApiDocument
        
        try nodes.assertHandlersLimitedToSingleNode()
    }
}
