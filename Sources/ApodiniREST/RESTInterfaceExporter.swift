//
// Created by Andreas Bauer on 22.11.20.
//

import Apodini
import Vapor
import NIO
import ApodiniVaporSupport

/// Public Apodini Interface Exporter for REST
public final class REST: Configuration {
    let configuration: REST.ExporterConfiguration
    var staticConfigurations: [RESTDependentStaticConfiguration]
    
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
    
    /**
     Initializes the configuration of the `RESTInterfaceExporter` with (default) `AnyEncoder` and `AnyDecoder`
     - Parameters:
         - encoder: The to be used `AnyEncoder`, defaults to a `JSONEncoder`
         - decoder: The to be used `AnyDecoder`, defaults to a `JSONDecoder`
         - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitivly
     */
    public init(encoder: AnyEncoder = defaultEncoder, decoder: AnyDecoder = defaultDecoder, caseInsensitiveRouting: Bool = false) {
        self.configuration = REST.ExporterConfiguration(encoder: encoder, decoder: decoder, caseInsensitiveRouting: caseInsensitiveRouting)
        self.staticConfigurations = [EmptyRESTDependentStaticConfiguration()]
    }
    
    public func configure(_ app: Apodini.Application) {
        /// Instanciate exporter
        let restExporter = RESTInterfaceExporter(app, self.configuration)
        
        /// Insert exporter into `InterfaceExporterStorage`
        app.registerExporter(exporter: restExporter)
        
        /// Configure attached related static configurations
        self.staticConfigurations.configure(app, parentConfiguration: self.configuration)
    }
}

extension REST {
    /**
     Initializes the configuration of the `RESTInterfaceExporter` with (default) JSON Coders and possibly associated Exporters (eg. OpenAPI Exporter)
     - Parameters:
         - encoder: The to be used `JSONEncoder`, defaults to a `JSONEncoder`
         - decoder: The to be used `JSONDecoder`, defaults to a `JSONDecoder`
         - caseInsensitiveRouting: Indicates whether the HTTP route is interpreted case-sensitivly
         - staticConfiguraiton: A result builder that allows passing dependend static Exporters like the OpenAPI Exporter
     */
    public convenience init(encoder: JSONEncoder = defaultEncoder as! JSONEncoder,
                            decoder: JSONDecoder = defaultDecoder as! JSONDecoder,
                            caseInsensitiveRouting: Bool = false,
                            @RESTDependentStaticConfigurationBuilder staticConfigurations: () -> [RESTDependentStaticConfiguration] = { [] }) {
        self.init(encoder: encoder, decoder: decoder, caseInsensitiveRouting: caseInsensitiveRouting)
        self.staticConfigurations = staticConfigurations()
    }
}

/// Internal Apodini Interface Exporter for REST
final class RESTInterfaceExporter: InterfaceExporter, TruthAnchor {
    static let parameterNamespace: [ParameterNamespace] = .individual
    
    let app: Vapor.Application
    let configuration: REST.Configuration
    let exporterConfiguration: REST.ExporterConfiguration
    
    /// Initialize `RESTInterfaceExporter` from `Application`
    init(_ app: Apodini.Application,
         _ exporterConfiguration: REST.ExporterConfiguration = REST.ExporterConfiguration()) {
        self.app = app.vapor.app
        self.configuration = REST.Configuration(app.vapor.app.http.server.configuration)
        self.exporterConfiguration = exporterConfiguration
    }
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        var pathBuilder = RESTPathBuilder()
        
        let relationshipEndpoint = endpoint[AnyRelationshipEndpointInstance.self].instance

        let absolutePath = endpoint.absoluteRESTPath
        absolutePath.build(with: &pathBuilder)

        let routesBuilder = pathBuilder.routesBuilder(app)
        
        let operation = endpoint[Operation.self]

        let endpointHandler = RESTEndpointHandler(with: configuration,
                                                  withExporterConfiguration: exporterConfiguration,
                                                  for: endpoint,
                                                  relationshipEndpoint,
                                                  on: self)
        endpointHandler.register(at: routesBuilder, using: operation)

        app.logger.info("Exported '\(Vapor.HTTPMethod(operation).rawValue) \(pathBuilder.pathDescription)' with parameters: \(endpoint[EndpointParameters.self].map { $0.name })")

        if relationshipEndpoint.inheritsRelationship {
            for selfRelationship in relationshipEndpoint.selfRelationships() where selfRelationship.destinationPath != absolutePath {
                app.logger.info("""
                                  - inherits from: \(Vapor.HTTPMethod(selfRelationship.operation).rawValue) \
                                \(selfRelationship.destinationPath.asPathString())
                                """)
            }
        }
        
        for operation in Operation.allCases.sorted(by: \.linksOperationPriority) {
            for destination in relationshipEndpoint.relationships(for: operation) {
                app.logger.info("  - links to: \(destination.destinationPath.asPathString())")
            }
        }
    }

    func finishedExporting(_ webService: WebServiceModel) {
        let root = webService[WebServiceRoot<RESTInterfaceExporter>.self]
        
        let relationshipModel = webService[RelationshipModelKnowledgeSource.self].model
        
        if root.node.endpoints[.read] == nil {
            // if the root path doesn't have a read endpoint we create a custom one, to deliver linking entry points.

            let relationships = relationshipModel.rootRelationships(for: .read)

            let handler = RESTDefaultRootHandler(configuration: configuration,
                                                 exporterConfiguration: exporterConfiguration,
                                                 relationships: relationships)
            handler.register(on: app)
            
            app.logger.info("Auto exported '\(HTTPMethod.GET.rawValue) /'")
            
            for relationship in relationships {
                app.logger.info("  - links to: \(relationship.destinationPath.asPathString())")
            }
        }
        
        // Set option to activate case insensitive routing, default is false (so case-sensitive)
        self.app.routes.caseInsensitive = self.exporterConfiguration.caseInsensitiveRouting
    }
    
    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Vapor.Request) throws -> Type?? {
        switch parameter.parameterType {
        case .lightweight:
            // Note: Vapor also supports decoding into a struct which holds all query parameters. Though we have the requirement,
            //   that .lightweight parameter types conform to LosslessStringConvertible, meaning our DSL doesn't allow for that right now
            guard let query = request.query[Type.self, at: parameter.name] else {
                return nil // the query parameter doesn't exists
            }
            return query
        case .path:
            guard let stringParameter = request.parameters.get(parameter.pathId) else {
                return nil // the path parameter didn't exist on that request
            }
            
            guard let value = parameter.initLosslessStringConvertibleParameterValue(from: stringParameter) else {
                throw ApodiniError(type: .badInput, reason: """
                                                            Encountered illegal input for path parameter \(parameter.name).
                                                            \(Type.self) can't be initialized from \(stringParameter).
                                                            """)
            }
            
            return value
        case .content:
            guard request.body.data != nil else {
                // If the request doesn't have a body, there is nothing to decide.
                return nil
            }
            
            return try? request.content.decode(Type.self, using: self.exporterConfiguration.decoder)
        }
    }
}


extension AnyEndpoint {
    /// RESTInterfaceExporter exports `@Parameter(.http(.path))`, which are not listed on the
    /// path-elements on the `Component`-tree as additional path elements at the end of the path.
    var absoluteRESTPath: [EndpointPath] {
        self[EndpointPathComponentsHTTP.self].value
    }
}
