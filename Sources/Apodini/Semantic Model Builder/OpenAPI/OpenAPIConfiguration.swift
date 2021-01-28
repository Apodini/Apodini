//
//  Created by Lorena Schlesinger on 15.11.20.
//

import Foundation
@_implementationOnly import OpenAPIKit

private let openAPIInfoTitle = "Apodini-App"
private let openAPIInfoVersion = "1.0.0"


/// A configuration structure for manually setting OpenAPI information and output locations.
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

extension OpenAPIConfiguration {
    init(from app: Application) {
        let host = app.vapor.app.http.server.configuration.hostname
        let port = app.vapor.app.http.server.configuration.port
        var servers: [OpenAPI.Server] = []
        if let url = URL(string: "\(host):\(port)") {
            let server = OpenAPI.Server(url: url)
            servers.append(server)
        }
        self.init(servers: servers)
    }
}
