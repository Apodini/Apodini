//
//  WebServiceStructure.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-31.
//

import Foundation
import Apodini



public enum WellKnownCLIArguments {
    /// The CLI argument used to tell Apodini to write the web service's structure to disk.
    /// In the support framework so that we can share this constant between Apodini (which needs to check for it)
    /// and the deployment provider (which needs to pass it to the invocation).
    public static let exportWebServiceModelStructure = "--apodini-dump-web-service-model-structure"

    /// The CLI argument used to tell an Apodini server that it's being launched with a custom config
    public static let launchWebServiceInstanceWithCustomConfig = "--apodini-launch-web-service-with-custom-config"
}


// Note: environment variables which are used in a lambda context must satisfy the regex `[a-zA-Z]([a-zA-Z0-9_])+`
public enum WellKnownEnvironmentVariables {
    public static let currentNodeId = "ApodiniDeployCurrentNodeId"
}



public struct ExporterIdentifier: RawRepresentable, Codable, Hashable, Equatable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}


public struct WebServiceStructure: Codable { // TODO this needs a better name. maybe Context or Summary?
    public let endpoints: Set<ExportedEndpoint>
    public let deploymentConfig: DeploymentConfig
    public let openApiDefinition: Data // TODO have this typed as `OpenAPI.Document` instead
    
    public init(
        endpoints: Set<ExportedEndpoint>,
        deploymentConfig: DeploymentConfig,
        openApiDefinition: Data
    ) {
        self.endpoints = endpoints
        self.deploymentConfig = deploymentConfig
        self.openApiDefinition = openApiDefinition
    }
}





public struct ExportedEndpoint: Codable, Hashable, Equatable {
    public let handlerType: HandlerTypeIdentifier
    /// Identifier of the  handler this endpoint was generated for
    public let handlerId: AnyHandlerIdentifier
    /// The endpoint's handler's deployment options
    public let deploymentOptions: DeploymentOptions
    /// Additional information about this endpoint
    public let userInfo: [String: Data]
    
    
    public init(
        handlerType: HandlerTypeIdentifier,
        handlerId: AnyHandlerIdentifier,
        deploymentOptions: DeploymentOptions,
        userInfo: [String: Data]
    ) {
        self.handlerType = handlerType
        self.handlerId = handlerId
        self.deploymentOptions = deploymentOptions
        self.userInfo = userInfo
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.handlerId)
    }
    
    public static func == (lhs: ExportedEndpoint, rhs: ExportedEndpoint) -> Bool {
        lhs.handlerId == rhs.handlerId
    }
}


