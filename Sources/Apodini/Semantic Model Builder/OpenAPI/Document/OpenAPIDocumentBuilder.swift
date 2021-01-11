//
// Created by Lorena Schlesinger on 13.12.20.
//

import Foundation
@_implementationOnly import OpenAPIKit

struct OpenAPIDocumentBuilder {
    var document: OpenAPI.Document {
        self.build()
    }
    let configuration: OpenAPIConfiguration
    var pathsObjectBuilder: OpenAPIPathsObjectBuilder
    var componentsObjectBuilder: OpenAPIComponentsObjectBuilder

    init(configuration: OpenAPIConfiguration) {
        self.configuration = configuration
        self.componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        self.pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: &self.componentsObjectBuilder)
    }

    mutating func addEndpoint<C: Component>(_ endpoint: Endpoint<C>) {
        pathsObjectBuilder.addPathItem(from: endpoint)
    }

    func build() -> OpenAPI.Document {
        OpenAPI.Document(
            info: configuration.info,
            servers: configuration.servers,
            paths: pathsObjectBuilder.pathsObject,
            components: componentsObjectBuilder.componentsObject
        )
    }
}

extension OpenAPIDocumentBuilder {
    // swiftlint:disable force_unwrapping
    var description: String {
        let encoder = JSONEncoder()
        guard let json = try? encoder.encode(self.document) else {
            return ""
        }
        return String(data: json, encoding: .utf8)!
    }
}
