//
//  OpenAPIConfiguration.swift
//  
//
//  Created by Lorena Schlesinger on 15.11.20.
//

import OpenAPIKit

private let openAPIInfoTitle = "Apodini-App"
private let openAPIInfoVersion = "1.0.0"


/// A configuration structure for manually setting OpenAPI information and output locations.
/// TODO: adjust when proposal of Apodini `configuration` is merged
struct OpenAPIConfiguration {
    /// General OpenAPI information.
    var info: OpenAPI.Document.Info = OpenAPI.Document.Info(title: openAPIInfoTitle, version: openAPIInfoVersion)
    
    /// Server configuration.
    var servers: [OpenAPI.Server] = []
    
    /// Output configuration (e.g., API endpoint or file output).
    enum OutputFormat {
        case JSON
        case YAML
    }
    var outputPath: String?
    var outputEndpoint: String? = "openapi"
    var outputFormat: OutputFormat = .JSON
}
