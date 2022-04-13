//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import NIO
import ApodiniUtils
import ApodiniNetworking
import ApodiniHTTPProtocol
import ApodiniMigrationCommon
import Foundation


/// Public Apodini Interface Exporter for REST
public final class REST: Configuration, ConfigurationWithDependents {
    public typealias InternalConfiguration = REST.ExporterConfiguration
    
    public var staticConfigurations: [AnyDependentStaticConfiguration] = []
    let configuration: REST.ExporterConfiguration
    
    /// The default `AnyEncoder`, a `JSONEncoder` with certain set parameters
    public static var defaultEncoder: AnyEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        return encoder
    }
    
    /// The default `AnyDecoder`, a `JSONDecoder`
    public static var defaultDecoder: AnyDecoder {
        JSONDecoder()
    }
    
    /// Initializes the configuration of the `RESTInterfaceExporter` with (default) `AnyEncoder` and `AnyDecoder`
    /// - Parameters:
    ///    - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
    ///    - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
    ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitively
    ///    - rootPath: Configures the root path for the HTTP endpoints
    public init(
        encoder: AnyEncoder = defaultEncoder,
        decoder: AnyDecoder = defaultDecoder,
        urlParamDateDecodingStrategy: ApodiniNetworking.DateDecodingStrategy = .default,
        caseInsensitiveRouting: Bool = false,
        rootPath: RootPath? = nil
    ) {
        self.configuration = REST.ExporterConfiguration(
            encoder: encoder,
            decoder: decoder,
            urlParamDateDecodingStrategy: urlParamDateDecodingStrategy,
            caseInsensitiveRouting: caseInsensitiveRouting,
            rootPath: rootPath
        )
    }
    
    public func configure(_ app: Apodini.Application) {
        /// Instantiate exporter
        let restExporter = RESTInterfaceExporter(app, self.configuration)
        
        /// Insert exporter into `InterfaceExporterStorage`
        app.registerExporter(exporter: restExporter)

        let encoderConfiguration: EncoderConfiguration
        let decoderConfiguration: DecoderConfiguration

        if let encoder = configuration.encoder as? JSONEncoder {
            encoderConfiguration = EncoderConfiguration(derivedFrom: encoder)
        } else {
            encoderConfiguration = .default
        }

        if let decoder = configuration.decoder as? JSONDecoder {
            decoderConfiguration = DecoderConfiguration(derivedFrom: decoder)
        } else {
            decoderConfiguration = .default
        }

        let rootPath = configuration.rootPath?.endpointPath(withVersion: app.version).description
        app.apodiniMigration.register(
            configuration: RESTExporterConfiguration(
                encoderConfiguration: encoderConfiguration,
                decoderConfiguration: decoderConfiguration,
                caseInsensitiveRouting: configuration.caseInsensitiveRouting,
                rootPath: rootPath
            ),
            for: .rest
        )

        /// Configure attached related static configurations
        self.staticConfigurations.configureAny(app, parentConfiguration: self.configuration)
    }
}

extension REST {
    /// Initializes the configuration of the `RESTInterfaceExporter` with (default) JSON Coders and possibly associated Exporters (eg. OpenAPI Exporter)
    /// - Parameters:
    ///    - encoder: The to be used `JSONEncoder`, defaults to a `JSONEncoder`
    ///    - decoder: The to be used `JSONDecoder`, defaults to a `JSONDecoder`
    ///    - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitively
    ///    - rootPath: Configures the root path for the HTTP endpoints
    ///    - staticConfigurations: A result builder that allows passing dependent static Exporters like the OpenAPI Exporter
    public convenience init(
        encoder: JSONEncoder = defaultEncoder as! JSONEncoder,
        decoder: JSONDecoder = defaultDecoder as! JSONDecoder,
        urlParamDateDecodingStrategy: ApodiniNetworking.DateDecodingStrategy = .default,
        caseInsensitiveRouting: Bool = false,
        rootPath: RootPath? = nil,
        @DependentStaticConfigurationBuilder<REST> staticConfigurations: () -> [AnyDependentStaticConfiguration] = { [] }
    ) {
        self.init(
            encoder: encoder,
            decoder: decoder,
            urlParamDateDecodingStrategy: urlParamDateDecodingStrategy,
            caseInsensitiveRouting: caseInsensitiveRouting,
            rootPath: rootPath
        )
        self.staticConfigurations = staticConfigurations()
    }
}

/// Internal Apodini Interface Exporter for REST
final class RESTInterfaceExporter: InterfaceExporter, TruthAnchor {
    static let parameterNamespace: [ParameterNamespace] = .individual
    
    let app: Apodini.Application
    let exporterConfiguration: REST.ExporterConfiguration
    
    /// Initialize `RESTInterfaceExporter` from `Application`
    init(_ app: Apodini.Application, _ exporterConfiguration: REST.ExporterConfiguration = REST.ExporterConfiguration()) {
        self.app = app
        self.exporterConfiguration = exporterConfiguration
    }
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        var pathBuilder = RESTPathBuilder()
        let relationshipEndpoint = endpoint[AnyRelationshipEndpointInstance.self].instance

        let absolutePath = endpoint.absoluteRESTPath(rootPrefix: exporterConfiguration.rootPath?.endpointPath(withVersion: app.version))
        absolutePath.build(with: &pathBuilder)
        
        let operation = endpoint[Operation.self]
        let endpointHandler = RESTEndpointHandler(
            with: app,
            withExporterConfiguration: exporterConfiguration,
            for: endpoint,
            relationshipEndpoint,
            on: self
        )
        app.httpServer.registerRoute(
            HTTPMethod(operation),
            pathBuilder.pathComponents,
            responder: endpointHandler
        )

        app.logger.info("Exported '\(HTTPMethod(operation).rawValue) \(pathBuilder.pathDescription)' with parameters: \(endpoint[EndpointParameters.self].map { $0.name })")

        if relationshipEndpoint.inheritsRelationship {
            for selfRelationship in relationshipEndpoint.selfRelationships() where selfRelationship.destinationPath != absolutePath {
                app.logger.info(
                    """
                      - inherits from: \(HTTPMethod(selfRelationship.operation).rawValue) \
                    \(selfRelationship.destinationPath.asPathString())
                    """
                )
            }
        }
        
        for operation in Operation.allCases.sorted(by: \.linksOperationPriority) {
            for destination in relationshipEndpoint.relationships(for: operation) {
                app.logger.info("  - links to: \(destination.destinationPath.asPathString())")
            }
        }
    }
    
    func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        export(endpoint)
    }

    func finishedExporting(_ webService: WebServiceModel) {
        let root = webService[WebServiceRoot<RESTInterfaceExporter>.self]
        let relationshipModel = webService[RelationshipModelKnowledgeSource.self].model
        
        if root.node.endpoints[.read] == nil {
            // if the root path doesn't have a read endpoint we create a custom one, to deliver linking entry points.
            let relationships = relationshipModel.rootRelationships(for: .read)
            let handler = RESTDefaultRootHandler(app: app, exporterConfiguration: exporterConfiguration, relationships: relationships)
            handler.register(on: app, rootPath: exporterConfiguration.rootPath?.endpointPath(withVersion: app.version))
            app.logger.info("Auto exported '\(HTTPMethod.GET.rawValue) /'")
            for relationship in relationships {
                app.logger.info("  - links to: \(relationship.destinationPath.asPathString())")
            }
        }
        
        // Set option to activate case insensitive routing, default is false (so case-sensitive)
        app.httpServer.isCaseInsensitiveRoutingEnabled = exporterConfiguration.caseInsensitiveRouting
    }
}

extension AnyEndpoint {
    /// RESTInterfaceExporter exports `@Parameter(.http(.path))`, which are not listed on the
    /// path-elements on the `Component`-tree as additional path elements at the end of the path.
    public func absoluteRESTPath(rootPrefix: EndpointPath?) -> [EndpointPath] {
        var path = self[EndpointPathComponentsHTTP.self].value
        if let rootPrefix = rootPrefix {
            path.insert(rootPrefix, at: 1)
        }
        return path
    }
}
