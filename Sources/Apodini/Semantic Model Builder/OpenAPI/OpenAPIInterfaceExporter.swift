//
//  OpenAPISemanticModelBuilder.swift
//  
//
//  Created by Paul Schmiedmayer on 11/3/20.


import OpenAPIKit
import Vapor
import Foundation
import Runtime

class OpenAPIInterfaceExporter: InterfaceExporter {
    let app: Application
    var configuration: OpenAPIConfiguration
    var document: OpenAPI.Document
    var openAPIComponentsBuilder = OpenAPIComponentsBuilder()
    var openAPIPathsBuilder = OpenAPIPathsBuilder()

    required init(_ app: Application) {
        self.app = app
        self.configuration = OpenAPIConfiguration()
        self.document = OpenAPI.Document(
                info: self.configuration.info,
                servers: self.configuration.servers,
                paths: OpenAPI.PathItem.Map(),
                components: self.openAPIComponentsBuilder.components
        )
        serveSpecification()
    }

    func export(_ endpoint: Endpoint) {
        var pathBuilder = OpenAPIPathBuilder(endpoint.absolutePath, parameters: endpoint.parameters)
        let path = pathBuilder.path
        var pathItem = self.document.paths[path] ?? OpenAPI.PathItem()
        let (op, httpMethod) = self.openAPIPathsBuilder.buildPathOperation(
                at: endpoint,
                with: endpoint.operation,
                using: openAPIComponentsBuilder
        )
        pathItem.set(operation: op, for: httpMethod)
        self.document.paths[path] = pathItem
    }

    func finishedExporting(_ webService: WebServiceModel) {
        self.document.components = self.openAPIComponentsBuilder.components
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
        if let outputRoute = self.configuration.outputEndpoint {
            switch self.configuration.outputFormat {
            case .JSON:
                app.get(outputRoute.pathComponents) { (_: Vapor.Request) in
                    self.document
                }
            case .YAML:
                print("Not implemented yet.")
            default:
                print("Not implemented yet.")
            }
        }
    }
}
