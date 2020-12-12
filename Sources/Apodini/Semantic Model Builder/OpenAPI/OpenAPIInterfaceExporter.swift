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
    
    func export(_ node: EndpointsTreeNode) {
        exportEndpoints(node)

        for child in node.children {
            export(child)
        }
    }
        
    func exportEndpoints(_ node: EndpointsTreeNode) {

        let path = OpenAPI.Path(stringLiteral: node.absolutePath.joinPathComponentsToOpenAPIPath())
        var pathItem = OpenAPI.PathItem()
        
        for (operation, endpoint) in node.endpoints {
            do {
                let (op, httpMethod) = try self.openAPIPathsBuilder.buildPathOperation(at: endpoint, with: operation, using: openAPIComponentsBuilder)
                pathItem.set(operation: op, for: httpMethod)
            } catch Operation.OpenAPIHTTPMethodError.unsupportedHttpMethod {
                app.logger.error("Error occurred when mapping Vapor HTTP method to OpenAPI HTTP method.")
            } catch {
                app.logger.error("Some unknown error occurred: \(error).")
            }
      
        if (pathItem.endpoints.count > 0){
            self.document.paths[path] = pathItem
            self.document.components = self.openAPIComponentsBuilder.components
            let encoder = JSONEncoder()
            if let json = try? encoder.encode(self.document) {
                print(String(data: json, encoding: .utf8)!)
            }
        }
    }
    }
        
func decode<T>(_ type: T.Type, from request: Vapor.Request) throws -> T? where T: Decodable {
    guard let byteBuffer = request.body.data, let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
        throw Vapor.Abort(.internalServerError, reason: "Could not read the HTTP request's body")
    }

    return try JSONDecoder().decode(type, from: data)
    }
}
