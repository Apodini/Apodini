//
//  Created by Paul Schmiedmayer on 11/3/20.
//

@_implementationOnly import OpenAPIKit
@_implementationOnly import Vapor
import Foundation

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
        app.storage.set(OpenAPIStorageKey.self, to: documentBuilder.build())
    }

    private func serveSpecification() {
        if let output = try? self.documentBuilder.document.output(self.configuration.outputFormat) {
            // register OpenAPI endpoint
            app.vapor.app.get(configuration.outputEndpoint.pathComponents) { _ -> String in
                output
            }
            
            // register swagger UI endpoint
            app.vapor.app.get(configuration.swaggerUiEndpoint.pathComponents) { _ -> Vapor.Response in
                var headers = HTTPHeaders()
                headers.add(name: .contentType, value: HTTPMediaType.html.serialize())
                guard let htmlFile = Bundle.module.path(forResource: "swagger-ui", ofType: "html") else {
                    throw Vapor.Abort(.internalServerError)
                }
                var html: String = try NSString(contentsOfFile: htmlFile, encoding: String.Encoding.ascii.rawValue) as String
                // replace placeholder with actual URL of OpenAPI endpoint
                html = html.replacingOccurrences(of: "{{OPEN_API_ENDPOINT_URL}}", with: self.configuration.outputEndpoint.pathComponents.string)
                return Vapor.Response(status: .ok, headers: headers, body: .init(string: html))
            }
        }
    }
}
