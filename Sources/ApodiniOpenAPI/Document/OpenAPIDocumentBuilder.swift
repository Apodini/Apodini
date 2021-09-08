//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import OpenAPIKit

/// Creates the OpenAPI specification document
/// https://swagger.io/specification/#openapi-object
struct OpenAPIDocumentBuilder {
    var document: OpenAPIKit.OpenAPI.Document {
        self.build()
    }
    
    let configuration: OpenAPI.ExporterConfiguration
    var pathsObjectBuilder: OpenAPIPathsObjectBuilder
    var componentsObjectBuilder: OpenAPIComponentsObjectBuilder
    
    init(configuration: OpenAPI.ExporterConfiguration) {
        self.configuration = configuration
        self.componentsObjectBuilder = OpenAPIComponentsObjectBuilder()
        self.pathsObjectBuilder = OpenAPIPathsObjectBuilder(componentsObjectBuilder: self.componentsObjectBuilder)
    }
    
    mutating func addEndpoint<H: Handler>(_ endpoint: Endpoint<H>) {
        pathsObjectBuilder.addPathItem(from: endpoint)
    }
    
    func build() -> OpenAPIKit.OpenAPI.Document {
        OpenAPIKit.OpenAPI.Document(
            info: OpenAPIKit.OpenAPI.Document.Info(
                title: configuration.title ?? "",
                description: configuration.webServiceDescription,
                termsOfService: configuration.termsOfService,
                contact: configuration.contact,
                license: configuration.license,
                version: configuration.version ?? ""
            ),
            servers: configuration.serverUrls.map {
                .init(url: $0)
            },
            paths: pathsObjectBuilder.pathsObject,
            components: componentsObjectBuilder.componentsObject,
            tags: configuration.tags,
            externalDocs: configuration.externalDocumentation
        )
    }
}
