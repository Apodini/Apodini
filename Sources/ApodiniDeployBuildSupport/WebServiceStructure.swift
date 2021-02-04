//
//  WebServiceStructure.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-31.
//

import Foundation



public enum WellKnownCLIArguments {
    /// The CLI argument used to tell Apodini to write the web service's structure to disk.
    /// In the support framework so that we can share this constant between Apodini (which needs to check for it)
    /// and the deployment provider (which needs to pass it to the invocation).
    public static let exportWebServiceModelStructure = "--apodini-dump-web-service-model-structure"

    /// The CLI argument used to tell an Apodini server that it's being launched with a custom config
    public static let launchWebServiceInstanceWithCustomConfig = "--apodini-launch-web-service-with-custom-config"
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
    public let endpoints: [ExportedEndpoint]
    public let deploymentConfig: DeploymentConfig
    public let openApiDefinition: Data
    
    public init(
        endpoints: [ExportedEndpoint],
        deploymentConfig: DeploymentConfig,
        openApiDefinition: Data
    ) {
        print("!!!!~!!!CREATING A WEBSERVICESTRUCTURE~~~~~")
        self.endpoints = endpoints
        self.deploymentConfig = deploymentConfig
        self.openApiDefinition = openApiDefinition
    }
}





public struct ExportedEndpoint: Codable, Hashable, Equatable {
    public let handlerType: String
    /// The `rawValue` of the identifier of the  handler this endpoint was generated for
    public let handlerIdRawValue: String
    /// The endpoint's handler's deployment options
    public let deploymentOptions: HandlerDeploymentOptions
    
    public let httpMethod: String
    public let absolutePath: String
    
    /// Additional information about this endpoint
    public let userInfo: [String: Data]
    
    
    public init(
        handlerType: String,
        handlerIdRawValue: String,
        deploymentOptions: HandlerDeploymentOptions,
        httpMethod: String,
        absolutePath: String,
        userInfo: [String: Data]
    ) {
        self.handlerType = handlerType
        self.handlerIdRawValue = handlerIdRawValue
        self.deploymentOptions = deploymentOptions
        self.httpMethod = httpMethod
        self.absolutePath = absolutePath
        self.userInfo = userInfo
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.handlerIdRawValue)
    }
    
    public static func == (lhs: ExportedEndpoint, rhs: ExportedEndpoint) -> Bool {
        lhs.handlerIdRawValue == rhs.handlerIdRawValue
    }
}


