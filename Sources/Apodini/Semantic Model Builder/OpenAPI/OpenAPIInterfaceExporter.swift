//
//  Created by Paul Schmiedmayer on 11/3/20.
//

@_implementationOnly import OpenAPIKit
@_implementationOnly import struct Vapor.Abort
import Foundation


struct OpenAPIDefStorageKey: StorageKey {
    typealias Value = OpenAPI.Document
}

class OpenAPIInterfaceExporter: StaticInterfaceExporter {
    static var parameterNamespace: [ParameterNamespace] = .individual

    let app: Application
    var documentBuilder: OpenAPIDocumentBuilder
    let configuration: OpenAPIConfiguration

    required init(_ app: Application) {
        self.app = app
        self.configuration = OpenAPIConfiguration(from: app)
        self.documentBuilder = OpenAPIDocumentBuilder(
            configuration: configuration
        )
    }

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        documentBuilder.addEndpoint(endpoint)
    }

    func finishedExporting(_ webService: WebServiceModel) {
        serveSpecification()
        app.storage.set(OpenAPIDefStorageKey.self, to: documentBuilder.build())
    }

    private func serveSpecification() {
        if let outputRoute = configuration.outputEndpoint {
            switch configuration.outputFormat {
            case .JSON:
                app.vapor.app.get(outputRoute.pathComponents) { _ -> String in
                    guard let jsonDescription = self.documentBuilder.jsonDescription else {
                        throw Abort(.internalServerError)
                    }
                    return jsonDescription
                }
            case .YAML:
                print("Not implemented yet.")
            }
        }
    }
}
