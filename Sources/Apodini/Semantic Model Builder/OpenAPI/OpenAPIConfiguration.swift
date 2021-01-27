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

    var outputFormat: OpenAPIOutputFormat = .json
    var outputEndpoint: String = "openapi"
    var swaggerUiEndpoint: String = "openapi-ui"
}

extension OpenAPIConfiguration {
    init(from app: Application) {
        let `protocol` = app.vapor.app.http.server.configuration.tlsConfiguration != nil ? "https" : "http"
        let host = app.vapor.app.http.server.configuration.hostname
        let port = app.vapor.app.http.server.configuration.port
        var servers: [OpenAPI.Server] = []
        if let url = URL(string: "\(`protocol`)://\(host):\(port)") {
            let server = OpenAPI.Server(url: url)
            servers.append(server)
        }
        self.init(servers: servers)
    }
}
