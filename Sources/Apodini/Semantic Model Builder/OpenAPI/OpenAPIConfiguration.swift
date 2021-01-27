//
//  Created by Lorena Schlesinger on 15.11.20.
//

import Foundation
@_implementationOnly import OpenAPIKit

/// The enclosing storage entity for OpenAPI-related information.
struct OpenAPIStorageValue {
    var document: OpenAPI.Document?
    var configuration: OpenAPIConfiguration
}

/// The storage key for OpenAPI-related information.
struct OpenAPIStorageKey: StorageKey {
    typealias Value = OpenAPIStorageValue
}

/// An enum specifying the output format of the OpenAPI specification document.
public enum OpenAPIOutputFormat {
    /// JSON format output.
    case json
    /// YAML format output.
    case yaml
}

/// A configuration structure for manually setting OpenAPI information and output locations.
public class OpenAPIConfiguration: Configuration {
    /// General OpenAPI information.
    var title: String?
    var version: String?

    /// Server configuration.
    var serverUrls: Set<URL> = Set<URL>()

    /// OpenAPI output configuration.
    let outputFormat: OpenAPIOutputFormat
    let outputEndpoint: String
    let swaggerUiEndpoint: String
    
    /// Configure application.
    public func configure(_ app: Application) {
        app.storage.set(OpenAPIStorageKey.self, to: OpenAPIStorageValue(configuration: self))
    }
    
    public init(
        outputFormat: OpenAPIOutputFormat = .json,
        outputEndpoint: String = "openapi",
        swaggerUiEndpoint: String = "openapi-ui",
        title: String? = nil,
        version: String? = nil,
        serverUrls: URL...
        ) {
        self.outputFormat = outputFormat
        self.outputEndpoint = outputEndpoint
        self.swaggerUiEndpoint = swaggerUiEndpoint
        self.serverUrls.formUnion(serverUrls)
        self.title = title
        self.version = version
    }
}
