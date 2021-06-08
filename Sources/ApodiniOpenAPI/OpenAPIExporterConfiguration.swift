//
//  Created by Lorena Schlesinger on 15.11.20.
//

import Foundation
import Apodini
import ApodiniREST
import OpenAPIKit

/// Default values used for OpenAPI configuration if not explicitly specified by developer.
public enum OpenAPIConfigurationDefaults {
    /// Default OpenAPI specification output format.
    public static let outputFormat: OpenAPIOutputFormat = .json
    /// Default OpenAPI specification output endpoint.
    public static let outputEndpoint: String = "openapi"
    /// Default swagger-UI endpoint.
    public static let swaggerUiEndpoint: String = "openapi-ui"
}

/// The enclosing storage entity for OpenAPI-related information.
public struct OpenAPIStorageValue {
    /// The OpenAPI document
    public let document: OpenAPI.Document?
    
    internal init(document: OpenAPI.Document? = nil) {
        self.document = document
    }
}

/// The storage key for OpenAPI-related information.
public struct OpenAPIStorageKey: StorageKey {
    public typealias Value = OpenAPIStorageValue
}

/// An enum specifying the output format of the OpenAPI specification document.
public enum OpenAPIOutputFormat {
    /// JSON format output.
    case json
    /// YAML format output.
    case yaml
    /// Use encoding configuration of parent
    case useParentEncoding
}

/// A configuration structure for manually setting OpenAPI information and output locations.
struct OpenAPIExporterConfiguration {
    /// General OpenAPI information.
    var title: String?
    var version: String?
    
    /// Server configuration.
    var serverUrls: Set<URL> = Set<URL>()
    
    /// OpenAPI output configuration.
    let outputFormat: OpenAPIOutputFormat
    let outputEndpoint: String
    let swaggerUiEndpoint: String
    
    /// Configuration of parent exporter
    var parentConfiguration: RESTExporterConfiguration
    
    init(
        parentConfiguration: RESTExporterConfiguration = RESTExporterConfiguration(),
        outputFormat: OpenAPIOutputFormat = OpenAPIConfigurationDefaults.outputFormat,
        outputEndpoint: String = OpenAPIConfigurationDefaults.outputEndpoint,
        swaggerUiEndpoint: String = OpenAPIConfigurationDefaults.swaggerUiEndpoint,
        title: String? = nil,
        version: String? = nil,
        serverUrls: [URL] = []
    ) {
        self.parentConfiguration = parentConfiguration
        self.outputFormat = outputFormat
        // Prefix configured endpoints with `/` to avoid relative paths.
        self.outputEndpoint = outputEndpoint.hasPrefix("/") ? outputEndpoint : "/\(outputEndpoint)"
        self.swaggerUiEndpoint = swaggerUiEndpoint.hasPrefix("/") ? swaggerUiEndpoint : "/\(swaggerUiEndpoint)"
        self.serverUrls.formUnion(serverUrls)
        self.title = title
        self.version = version
    }
}
