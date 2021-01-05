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
        self.configuration = OpenAPIConfiguration.create(from: app)
        self.documentBuilder = OpenAPIDocumentBuilder(
                configuration: configuration
        )
    }

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        documentBuilder.addEndpoint(endpoint)
    }

    func finishedExporting(_ webService: WebServiceModel) {
        serveSpecification()
    }

    private func serveSpecification() {
        // swiftlint:disable:next todo
        // TODO: add YAML and default case?
        // swiftlint:disable:next todo
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

    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Vapor.Request) throws -> Type?? {
        fatalError("OpenAPIInterfaceExporter is not intended to retrieve parameters.")
    }
}
