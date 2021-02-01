//
// Created by Lorena Schlesinger on 13.12.20.
//

import Foundation
@_implementationOnly import OpenAPIKit

/// Creates the OpenAPI specification document
/// https://swagger.io/specification/#openapi-object
struct OpenAPIDocumentBuilder {
    var document: OpenAPI.Document {
        self.build()
    }
    var configuration: OpenAPIConfiguration
    var pathsObjectBuilder: OpenAPIPathsObjectBuilder
    var componentsObjectBuilder: OpenAPIComponentsObjectBuilder

    init(configuration: OpenAPIConfiguration) {
        self.configuration = configuration
        self.componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        self.pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &self.componentsObjectBuilder)
    }

    mutating func addEndpoint<H: Handler>(_ endpoint: Endpoint<H>) {
        pathsObjectBuilder.addPathItem(from: endpoint)
    }

    func build() -> OpenAPI.Document {
        OpenAPI.Document(
            info: OpenAPI.Document.Info(
                title: configuration.title ?? "",
                version: configuration.version ?? ""
            ),
            servers: configuration.serverUrls.map {
                .init(url: $0)
            },
            paths: pathsObjectBuilder.pathsObject,
            components: componentsObjectBuilder.componentsObject
        )
    }
}
