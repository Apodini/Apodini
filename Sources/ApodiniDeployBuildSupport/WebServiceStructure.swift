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
    public let interfaceExporterId: ExporterIdentifier
    public let endpoints: [ExportedEndpoint]
    public let deploymentConfig: DeploymentConfig
    
    public init(
        interfaceExporterId: ExporterIdentifier,
        endpoints: [ExportedEndpoint],
        deploymentConfig: DeploymentConfig
    ) {
        self.interfaceExporterId = interfaceExporterId
        self.endpoints = endpoints
        self.deploymentConfig = deploymentConfig
    }
}





public struct ExportedEndpoint: Codable, Equatable {
    /// The `rawValue` of the identifier of the  handler this endpoint was generated for
    public let handlerIdRawValue: String
    
    public let httpMethod: String
    public let absolutePath: String
    
    /// Additional information about this endpoint
    public let userInfo: [String: Data]
    
    
    public init(
        handlerIdRawValue: String,
        httpMethod: String,
        absolutePath: String,
        userInfo: [String: Data]
    ) {
        self.handlerIdRawValue = handlerIdRawValue
        self.httpMethod = httpMethod
        self.absolutePath = absolutePath
        self.userInfo = userInfo
    }
    
    public static func == (lhs: ExportedEndpoint, rhs: ExportedEndpoint) -> Bool {
        lhs.handlerIdRawValue == rhs.handlerIdRawValue
    }
}


