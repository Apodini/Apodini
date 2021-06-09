//
// Created by Andreas Bauer on 22.11.20.
//

import Apodini
import Vapor
import NIO

extension Vapor.Request: ExporterRequest, WithEventLoop, WithRemote {}

/// Public Apodini Interface Exporter for REST
public final class RESTInterfaceExporter: Configuration {
    let configuration: RESTExporterConfiguration
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
     */
    public init(encoder: AnyEncoder = defaultEncoder, decoder: AnyDecoder = defaultDecoder) {
        self.configuration = RESTExporterConfiguration(encoder: encoder, decoder: decoder)
        self.staticConfigurations = [EmptyRESTDependentStaticConfiguration()]
    }
    
    public func configure(_ app: Apodini.Application) {
        /// Instanciate exporter
        let restExporter = _RESTInterfaceExporter(app, self.configuration)
        
        /// Insert exporter into `SemanticModelBuilder`
        let builder = app.exporters.semanticModelBuilderBuilder
        app.exporters.semanticModelBuilderBuilder = { model in
            builder(model).with(exporter: restExporter)
        }
        
        /// Configure attached related static configurations
        self.staticConfigurations.configure(app, parentConfiguration: self.configuration)
    }
}

extension RESTInterfaceExporter {
    /**
     Initializes the configuration of the `RESTInterfaceExporter` with (default) JSON Coders and possibly associated Exporters (eg. OpenAPI Exporter)
     - Parameters:
         - encoder: The to be used `JSONEncoder`, defaults to a `JSONEncoder`
         - decoder: The to be used `JSONDecoder`, defaults to a `JSONDecoder`
         - staticConfiguraiton: A result builder that allows passing dependend static Exporters like the OpenAPI Exporter
     */
    public convenience init(encoder: JSONEncoder = defaultEncoder as! JSONEncoder,
                            decoder: JSONDecoder = defaultDecoder as! JSONDecoder,
                            @RESTDependentStaticConfigurationBuilder staticConfigurations: () -> [RESTDependentStaticConfiguration] = { [] }) {
        self.init(encoder: encoder, decoder: decoder)
        self.staticConfigurations = staticConfigurations()
    }
}

/// Internal Apodini Interface Exporter for REST
// swiftlint:disable type_name
final class _RESTInterfaceExporter: InterfaceExporter {
    static let parameterNamespace: [ParameterNamespace] = .individual
    
    let app: Vapor.Application
    let exporterConfiguration: RESTConfiguration
    
    /// Initialize `RESTInterfaceExporter` from `Application`
    init(_ app: Apodini.Application,
         _ exporterConfiguration: RESTExporterConfiguration = RESTExporterConfiguration()) {
        self.app = app.vapor.app
        self.exporterConfiguration = RESTConfiguration(app.vapor.app.http.server.configuration,
                                                       exporterConfiguration: exporterConfiguration)
    }
    
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        var pathBuilder = RESTPathBuilder()
        endpoint.absolutePath.build(with: &pathBuilder)
        
        let routesBuilder = pathBuilder.routesBuilder(app)
        
        let operation = endpoint[Operation.self]
        
        let endpointHandler = RESTEndpointHandler(with: exporterConfiguration, for: endpoint, on: self)
        endpointHandler.register(at: routesBuilder, using: operation)
        
        app.logger.info("Exported '\(Vapor.HTTPMethod(operation).rawValue) \(pathBuilder.pathDescription)' with parameters: \(endpoint.parameters.map { $0.name })")
        
        if endpoint.inheritsRelationship {
            for selfRelationship in endpoint.selfRelationships() where selfRelationship.destinationPath != endpoint.absolutePath {
                app.logger.info("""
                                  - inherits from: \(Vapor.HTTPMethod(selfRelationship.operation).rawValue) \
                                \(selfRelationship.destinationPath.asPathString())
                                """)
            }
        }
        
        for operation in Operation.allCases.sorted(by: \.linksOperationPriority) {
            for destination in endpoint.relationships(for: operation) {
                app.logger.info("  - links to: \(destination.destinationPath.asPathString())")
            }
        }
    }
    
    func finishedExporting(_ webService: WebServiceModel) {
        if webService.getEndpoint(for: .read) == nil {
            // if the root path doesn't have a read endpoint we create a custom one, to deliver linking entry points.
            
            let relationships = webService.rootRelationships(for: .read)
            
            let handler = RESTDefaultRootHandler(configuration: exporterConfiguration, relationships: relationships)
            handler.register(on: app)
            
            app.logger.info("Auto exported '\(HTTPMethod.GET.rawValue) /'")
            
            for relationship in relationships {
                app.logger.info("  - links to: \(relationship.destinationPath.asPathString())")
            }
        }
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
            return try? request.content.decode(Type.self, using: self.exporterConfiguration.exporterConfiguration.decoder)
            
        case .header:
            return request.headers.first(name: parameter.name) as? Type
        }
    }
}
