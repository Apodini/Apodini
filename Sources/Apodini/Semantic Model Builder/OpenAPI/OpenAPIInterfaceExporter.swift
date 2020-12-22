//
//  Created by Paul Schmiedmayer on 11/3/20.
//

@_implementationOnly import OpenAPIKit
@_implementationOnly import Vapor
import Foundation

class OpenAPIInterfaceExporter: InterfaceExporter {
    let app: Application
    var documentBuilder: OpenAPIDocumentBuilder
    let configuration: OpenAPIConfiguration

    required init(_ app: Application) {
        self.app = app
        let host = app.http.server.configuration.hostname
        let port = app.http.server.configuration.port
        var servers: [OpenAPI.Server] = []
        if let url = URL(string: "\(host):\(port)") {
            let server = OpenAPI.Server(url: url)
            servers.append(server)
        }
        self.configuration = OpenAPIConfiguration(servers: servers)
        documentBuilder = OpenAPIDocumentBuilder(
                configuration: configuration
        )
    }

    func export(_ endpoint: Endpoint) {
        documentBuilder.addEndpoint(endpoint)
    }

    func finishedExporting(_ webService: WebServiceModel) {
        serveSpecification()
    }

    private func serveSpecification() {
        // TODO: add YAML and default case?
        // TODO: add file export?
        if let outputRoute = configuration.outputEndpoint {
            switch configuration.outputFormat {
            case .JSON:
                app.get(outputRoute.pathComponents) { (_: Vapor.Request) in
                    self.documentBuilder.description
                }
            case .YAML:
                print("Not implemented yet.")
            default:
                print("Not implemented yet.")
            }
        }
    }
}
