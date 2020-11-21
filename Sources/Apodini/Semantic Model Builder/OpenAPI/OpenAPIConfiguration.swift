//
//  OpenAPIConfiguration.swift
//  
//
//  Created by Lorena Schlesinger on 15.11.20.
//

import OpenAPIKit

let DEFAULT_OPEN_API_INFO_TITLE = "Apodini-App"
let DEFAULT_OPEN_API_INFO_VERSION = "1.0.0"

/// A configuration structure for manually setting OpenAPI information and output locations.
struct OpenAPIConfiguration {

    /// General OpenAPI information.
    var info: OpenAPI.Document.Info = OpenAPI.Document.Info(title: DEFAULT_OPEN_API_INFO_TITLE, version: DEFAULT_OPEN_API_INFO_VERSION)
    
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
