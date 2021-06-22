//
//  Created by Paul Schmiedmayer on 11/3/20.
//

import Foundation
import Apodini
import ApodiniREST
import ApodiniVaporSupport
@_implementationOnly import Vapor
import OpenAPIKit

/// Public Apodini Interface Exporter for OpenAPI
public final class OpenAPI: RESTDependentStaticConfiguration {
    var configuration: OpenAPI.ExporterConfiguration
    
    public init(outputFormat: OpenAPI.OutputFormat = OpenAPI.ConfigurationDefaults.outputFormat,
                outputEndpoint: String = OpenAPI.ConfigurationDefaults.outputEndpoint,
                swaggerUiEndpoint: String = OpenAPI.ConfigurationDefaults.swaggerUiEndpoint,
                title: String? = nil,
                version: String? = nil,
                serverUrls: URL...) {
        self.configuration = OpenAPI.ExporterConfiguration(
                                outputFormat: outputFormat,
                                outputEndpoint: outputEndpoint,
                                swaggerUiEndpoint: swaggerUiEndpoint,
                                title: title,
                                version: version,
                                serverUrls: serverUrls)
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: REST.ExporterConfiguration) {
        /// Set configartion of parent
        self.configuration.parentConfiguration = parentConfiguration
        
        /// Instanciate exporter
        let openAPIExporter = OpenAPIInterfaceExporter(app, self.configuration)
        
        /// Insert exporter into `InterfaceExporterStorage`
        app.registerExporter(staticExporter: openAPIExporter)
    }
}

/// Internal Apodini Interface Exporter for OpenAPI
final class OpenAPIInterfaceExporter: StaticInterfaceExporter {
    static var parameterNamespace: [ParameterNamespace] = .individual
    
    let app: Apodini.Application
    var documentBuilder: OpenAPIDocumentBuilder
    var exporterConfiguration: OpenAPI.ExporterConfiguration
    
    /// Initalize`OpenAPIInterfaceExporter` from `Application`
    init(_ app: Apodini.Application,
         _ exporterConfiguration: OpenAPI.ExporterConfiguration = OpenAPI.ExporterConfiguration()) {
        self.app = app
        self.exporterConfiguration = exporterConfiguration
        
        self.documentBuilder = OpenAPIDocumentBuilder(
            configuration: self.exporterConfiguration
        )
        setApplicationServer(from: app)
        updateStorage()
    }
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        documentBuilder.addEndpoint(endpoint)
        
        // Set version information from APIContextKey, if the version was not defined by developer.
        if self.exporterConfiguration.version == nil {
            self.exporterConfiguration.version = endpoint[Context.self].get(valueFor: APIVersionContextKey.self)?.description
            //updateStorage()
        }
    }
    
    func finishedExporting(_ webService: WebServiceModel) {
        serveSpecification()
        updateStorage()
    }
    
    private func setApplicationServer(from app: Apodini.Application) {
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
            self.exporterConfiguration.serverUrls.insert(url)
        }
    }
    
    private func updateStorage() {
        app.storage.set(
            OpenAPI.StorageKey.self,
            to: OpenAPI.StorageValue(
                document: self.documentBuilder.document
            )
        )
    }
    
    private func serveSpecification() {
        if let output = try? self.documentBuilder.document.output(configuration: self.exporterConfiguration) {
            // Register OpenAPI specification endpoint.
            app.vapor.app.get(exporterConfiguration.outputEndpoint.pathComponents) { _ -> String in
                output
            }
            
            // Register swagger-UI endpoint.
            app.vapor.app.get(exporterConfiguration.swaggerUiEndpoint.pathComponents) { _ -> Vapor.Response in
                var headers = HTTPHeaders()
                headers.add(name: .contentType, value: HTTPMediaType.html.serialize())
                guard let htmlFile = Bundle.module.path(forResource: "swagger-ui", ofType: "html"),
                      var html = try? String(contentsOfFile: htmlFile)
                else {
                    throw Vapor.Abort(.internalServerError)
                }
                // Replace placeholder with actual URL of OpenAPI specification endpoint.
                html = html.replacingOccurrences(of: "{{OPEN_API_ENDPOINT_URL}}", with: self.exporterConfiguration.outputEndpoint)
                
                return Vapor.Response(status: .ok, headers: headers, body: .init(string: html))
            }
            
            // Inform developer about serving on configured endpoints.
            self.app.logger.info("OpenAPI specification served in \(exporterConfiguration.outputFormat) format on: \(exporterConfiguration.outputEndpoint)")
            self.app.logger.info("Swagger-UI on: \(exporterConfiguration.swaggerUiEndpoint)")
        }
    }
}
