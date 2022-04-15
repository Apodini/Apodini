//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniREST
import OpenAPIKit
import ApodiniHTTP


extension ApodiniOpenAPI.OpenAPI {
    /// A configuration structure for manually setting OpenAPI information and output locations.
    class ExporterConfiguration {
        /// General OpenAPI information.
        var title: String?
        var version: String?

        // data retrieved from web service metadata declarations
        var webServiceDescription: String?
        var termsOfService: URL?
        var contact: OpenAPIKit.OpenAPI.Document.Info.Contact?
        var license: OpenAPIKit.OpenAPI.Document.Info.License?
        var tags: [OpenAPIKit.OpenAPI.Tag]? // swiftlint:disable:this discouraged_optional_collection
        var externalDocumentation: OpenAPIKit.OpenAPI.ExternalDocumentation?

        /// Server configuration.
        var serverUrls: Set<URL> = Set<URL>()
        
        /// OpenAPI output configuration.
        let outputFormat: OutputFormat
        let outputEndpoint: String
        let swaggerUiEndpoint: String
        
        /// Configuration of parent exporter
        var parentConfiguration: HTTPExporterConfiguration
        
        init(
            parentConfiguration: HTTPExporterConfiguration = HTTPExporterConfiguration(),
            outputFormat: OutputFormat = ConfigurationDefaults.outputFormat,
            outputEndpoint: String = ConfigurationDefaults.outputEndpoint,
            swaggerUiEndpoint: String = ConfigurationDefaults.swaggerUiEndpoint,
            title: String? = nil,
            version: String? = nil,
            serverUrls: [URL] = []
        ) {
            self.parentConfiguration = parentConfiguration
            self.outputFormat = outputFormat
            // Prefix configured endpoints with `/` to avoid relative paths.
            self.outputEndpoint = outputEndpoint.hasPrefix("/") ? outputEndpoint : "/\(outputEndpoint)"
            self.swaggerUiEndpoint = swaggerUiEndpoint.hasPrefix("/") ? swaggerUiEndpoint : "/\(swaggerUiEndpoint)"
            self.serverUrls.formUnion(serverUrls)
            self.title = title
            self.version = version
        }
    }
    
    /// Default values used for OpenAPI configuration if not explicitly specified by developer.
    public enum ConfigurationDefaults {
        /// Default OpenAPI specification output format.
        public static let outputFormat: OutputFormat = .json
        /// Default OpenAPI specification output endpoint.
        public static let outputEndpoint: String = "openapi"
        /// Default swagger-UI endpoint.
        public static let swaggerUiEndpoint: String = "openapi-ui"
    }

    /// The enclosing storage entity for OpenAPI-related information.
    public struct StorageValue {
        /// The OpenAPI document
        public let document: OpenAPIKit.OpenAPI.Document?
        
        internal init(document: OpenAPIKit.OpenAPI.Document? = nil) {
            self.document = document
        }
    }

    /// The storage key for OpenAPI-related information.
    public struct StorageKey: Apodini.StorageKey {
        public typealias Value = StorageValue
    }

    /// An enum specifying the output format of the OpenAPI specification document.
    public enum OutputFormat {
        /// JSON format output.
        case json
        /// YAML format output.
        case yaml
        /// Use encoding configuration of parent
        case useParentEncoding
    }
}
