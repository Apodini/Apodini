//
//  LambdaCommon.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-18.
//

import Foundation
import ApodiniDeployBuildSupport


public let LambdaDeploymentProviderId = DeploymentProviderID(rawValue: "de.lukaskollmer.ApodiniDeploymentProvider.AWSLambda")


// the DeployedSystemStructure user info for lambda deployments
public struct LambdaDeployedSystemContext: Codable {
    public let awsRegion: String
    public let apiGatewayApiId: String
    
    public init(awsRegion: String, apiGatewayApiId: String) {
        self.awsRegion = awsRegion
        self.apiGatewayApiId = apiGatewayApiId
    }
}


extension LambdaDeployedSystemContext {
    public var apiGatewayHostname: String {
        "\(apiGatewayApiId).execute-api.\(awsRegion).amazonaws.com"
    }
}
//
//
//// The class used to identify lambda-specific deployment options
//public final class LambdaHandlerOptionKey<Value: Codable>: DeploymentOptionKey<Value> {}
//
//
//// All lambda-specific deployment options
//public enum LambdaHandlerOption {
//    /// The lambda function's memory size, in MB
//    public static let memorySize = LambdaHandlerOptionKey<Int>(defaultValue: 128, key: "memory-size")
//    /// The lambda function's timeout, in seconds
//    public static let timeout = LambdaHandlerOptionKey<Int>(defaultValue: 3, key: "timeout")
//}



public final class LambdaDeploymentOptionsNamespace: InnerNamespace {
    public typealias OuterNS = DeploymentOptionsNamespace
    public static let id = LambdaDeploymentProviderId.rawValue
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
        fatalError("self: \(self), other: \(other)")
    }
}



public extension OptionKey where InnerNS == LambdaDeploymentOptionsNamespace, Value == LambdaDescriptionOption {
    static let lambdaDescription = OptionKey<DeploymentOptionsNamespace, LambdaDeploymentOptionsNamespace, LambdaDescriptionOption>(key: "description")
}



public extension AnyOption where OuterNS == DeploymentOptionsNamespace {
    static func lambdaDescription(_ value: LambdaDescriptionOption) -> AnyOption {
        return ResolvedOption(key: .lambdaDescription, value: value)
    }
}



