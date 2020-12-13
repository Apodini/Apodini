//
//  Created by Paul Schmiedmayer on 11/3/20.
//

import OpenAPIKit
import Vapor
import Foundation

class OpenAPIInterfaceExporter: InterfaceExporter {
    let app: Application
    var documentBuilder: OpenAPIDocumentBuilder
    let configuration: OpenAPIConfiguration = OpenAPIConfiguration()

    required init(_ app: Application) {
        self.app = app
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

    func decode<T>(_ type: T.Type, from request: Vapor.Request) throws -> T? where T: Decodable {
        guard let byteBuffer = request.body.data, let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
            throw Vapor.Abort(.internalServerError, reason: "Could not read the HTTP request's body")
        }
        return try JSONDecoder().decode(type, from: data)
    }

    private func serveSpecification() {
        // TODO: add YAML and default case?
        // TODO: add file export?
        if let outputRoute = configuration.outputEndpoint {
            switch configuration.outputFormat {
            case .JSON:
                app.get(outputRoute.pathComponents) { (_: Vapor.Request) in
                    self.documentBuilder.document
                }
            case .YAML:
                print("Not implemented yet.")
            default:
                print("Not implemented yet.")
            }
        }
    }
}
