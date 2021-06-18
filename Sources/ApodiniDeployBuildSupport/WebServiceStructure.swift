//
//  WebServiceStructure.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-31.
//

import Foundation
import Apodini
import ApodiniUtils
import OpenAPIKit


/// Well-known environment variables, i.e. environment variables which are read by Apodini and used when performing certain tasks.
/// Note: environment variables which are used in a lambda context must satisfy the regex `[a-zA-Z]([a-zA-Z0-9_])+`
public enum WellKnownEnvironmentVariables {
    /// Key for an environment variable specifying the current instance's node id (relative to the whole deployed system).
    /// This environment variable is only set of the web service is running as part of a managed deployment.
    public static let currentNodeId = "AD_CURRENT_NODE_ID"
    
    /// Key for an environment variable specifying the execution mode of ApodiniDeploy, ether dump the WebService's model structur or launch the WebService with custom config
    public static let executionMode = "AD_EXECUTION_MODE"
    
    /// Key for an environment variable specifying the url of the directory used for ApodiniDeploy, either the outputURL or configURL
    public static let fileUrl = "AD_INPUT_FILE_PATH"
}

// swiftlint:disable type_name
/// Possible values of the well-known environment variable `WellKnownEnvironmentVariables.executionMode`
public enum WellKnownEnvironmentVariableExecutionMode {
    /// Value of an environment variable to tell Apodini to write the web service's structure to disk.
    /// In the support framework so that we can share this constant between Apodini (which needs to check for it)
    /// and the deployment provider (which needs to pass it to the invocation).
    public static let exportWebServiceModelStructure = "ApodiniDumpWebSericeModelStructure"
    
    /// Value of an environment variable to tell an Apodini server that it's being launched with a custom config
    public static let launchWebServiceInstanceWithCustomConfig = "ApodiniLaunchWebServiceInstanceWithCustomConfig"
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


public struct WebServiceStructure: Codable {
    public let endpoints: Set<ExportedEndpoint>
    public let deploymentConfig: DeploymentConfig
    public let openApiDocument: OpenAPI.Document
    public let enabledDeploymentProviders: [DeploymentProviderID]
    
    public init(
        endpoints: Set<ExportedEndpoint>,
        deploymentConfig: DeploymentConfig,
        openApiDocument: OpenAPI.Document,
        enabledDeploymentProviders: [DeploymentProviderID]
    ) {
        self.endpoints = endpoints
        self.deploymentConfig = deploymentConfig
        self.openApiDocument = openApiDocument
        self.enabledDeploymentProviders = enabledDeploymentProviders
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
        userInfo: [String: Data] = [:]
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
