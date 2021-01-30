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
    var configuration: OpenAPIConfiguration

    required init(_ app: Application) {
        self.app = app
        if let storage = app.storage.get(OpenAPIStorageKey.self) {
            self.configuration = storage.configuration
        } else {
            self.configuration = OpenAPIConfiguration()
        }
        self.documentBuilder = OpenAPIDocumentBuilder(
            configuration: configuration
        )
        setApplicationServer(from: app)
        updateStorage()
    }

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        documentBuilder.addEndpoint(endpoint)
        
        // set version information from APIContextKey, if version was not defined by developer
        if self.configuration.version == nil {
            self.configuration.version = endpoint.context.get(valueFor: APIVersionContextKey.self)?.description
            updateStorage()
        }
    }

    func finishedExporting(_ webService: WebServiceModel) {
        serveSpecification()
        updateStorage()
    }
    
    private func setApplicationServer(from app: Application) {
        let isHttps = app.http.tlsConfiguration != nil
        var hostName: String?
        var port: Int?
        if case let .hostname(configuredHost, port: configuredPort) = app.http.address {
            hostName = configuredHost
            port = configuredPort
        } else {
            hostName = app.vapor.app.http.server.configuration.hostname
            port = app.vapor.app.http.server.configuration.port
        }
        if let hostName = hostName, let port = port, let url = URL(string: "\(isHttps ? "https" : "http")://\(hostName):\(port)") {
            self.configuration.serverUrls.insert(url)
        }
    }
    
    private func updateStorage() {
        app.storage.set(
            OpenAPIStorageKey.self,
            to: OpenAPIStorageValue(
                document: self.documentBuilder.document,
                configuration: self.configuration
            )
        )
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
                guard let htmlFile = Bundle.module.path(forResource: "swagger-ui", ofType: "html"),
                      var html = try? String(contentsOfFile: htmlFile)
                else {
                    throw Vapor.Abort(.internalServerError)
                }
                // replace placeholder with actual URL of OpenAPI endpoint
                html = html.replacingOccurrences(of: "{{OPEN_API_ENDPOINT_URL}}", with: self.configuration.outputEndpoint.pathComponents.string)
                return Vapor.Response(status: .ok, headers: headers, body: .init(string: html))
            }
        }
    }
}
