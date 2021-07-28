//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import ApodiniDeployBuildSupport
import OpenAPIKit


/// Identifier of the lambda deployment provider.
public let lambdaDeploymentProviderId = DeploymentProviderID("de.lukaskollmer.ApodiniDeploymentProvider.AWSLambda")


// the DeployedSystem user info for lambda deployments
public struct LambdaDeployedSystemContext: Codable {
    public let awsRegion: String
    public let apiGatewayApiId: String
    
    public init(awsRegion: String, apiGatewayApiId: String) {
        self.awsRegion = awsRegion
        self.apiGatewayApiId = apiGatewayApiId
    }
}


extension LambdaDeployedSystemContext {
    /// The hostname of this Lambda's API Gateway
    public var apiGatewayHostname: String {
        "\(apiGatewayApiId).execute-api.\(awsRegion).amazonaws.com"
    }
}


public struct LambdaDeploymentOptionsNamespace: InnerNamespace {
    public typealias OuterNS = DeploymentOptionsNamespace
    public static let identifier = lambdaDeploymentProviderId.rawValue
}


public struct LambdaDescriptionOption: OptionValue, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
    public func reduce(with other: LambdaDescriptionOption) -> LambdaDescriptionOption {
        fatalError("Conflicting lambda descriptions specified ('\(self.rawValue)' vs '\(other.rawValue)').")
    }
}


public extension OptionKey where InnerNS == LambdaDeploymentOptionsNamespace, Value == LambdaDescriptionOption {
    /// Lambda description option key.
    static let lambdaDescription =
        OptionKey<LambdaDeploymentOptionsNamespace, LambdaDescriptionOption>(key: "description")
}


public extension AnyOption where OuterNS == DeploymentOptionsNamespace {
    /// Option for specifying the description of the lambda generated for this deployment group.
    static func lambdaDescription(_ value: LambdaDescriptionOption) -> AnyOption {
        ResolvedOption(key: .lambdaDescription, value: value)
    }
}

public struct LambdaDeployedSystem: AnyDeployedSystem {
    public var userInfo: Data
    
    public var nodes: Set<DeployedSystemNode>
    
    public var deploymentProviderId: DeploymentProviderID
    
    public var openApiDocument: OpenAPI.Document
    
    public init<T: Encodable>(
        deploymentProviderId: DeploymentProviderID,
        nodes: Set<DeployedSystemNode>,
        userInfo: T?,
        userInfoType: T.Type = T.self,
        openApiDocument: OpenAPI.Document
    ) throws {
        self.deploymentProviderId = deploymentProviderId
        self.nodes = nodes
        self.userInfo = try JSONEncoder().encode(userInfo)
        self.openApiDocument = openApiDocument
        
        try nodes.assertHandlersLimitedToSingleNode()
    }
}
