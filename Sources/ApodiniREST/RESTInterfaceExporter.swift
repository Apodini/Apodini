//
// Created by Andreas Bauer on 22.11.20.
//

import Apodini
import ApodiniUtils
import Vapor
import NIO

extension Vapor.Request: ExporterRequest, WithEventLoop, WithRemote {}

public final class _RESTInterfaceExporter: Configuration {
    let configuration: RESTExporterConfiguration
    let staticConfigurations: [StaticConfiguration]
    
    public init(encoder: AnyEncoder = JSONEncoder(), decoder: AnyDecoder = JSONDecoder(), @StaticConfigurationBuilder staticConfigurations: () -> [StaticConfiguration] = {[]}) {
        self.configuration = RESTExporterConfiguration(encoder: encoder, decoder: decoder)
        self.staticConfigurations = staticConfigurations()
    }
    
    public func configure(_ app: Apodini.Application) {
        guard var semanticModel = app.storage.get(SemanticModelBuilderKey.self) else {
            fatalError("Semantic Model in Storage is not set!")
        }
        
        /// Insert current exporter into `SemanticModelBuilder`
        let restExporter = RESTInterfaceExporter(app, self.configuration)
        semanticModel = semanticModel.with(exporter: restExporter)
        
        /// Configure attached related static configurations
        self.staticConfigurations.configure(app, parentConfiguration: self.configuration)
        
        /// Doesn't have to be set again since it's by-reference
        //app.storage.set(SemanticModelBuilderKey.self, to: semanticModel)
    }
}
 
/// Apodini Interface Exporter for REST
public final class RESTInterfaceExporter: InterfaceExporter {
    public static let parameterNamespace: [ParameterNamespace] = .individual

    let app: Vapor.Application
    let exporterConfiguration: RESTConfiguration

    /// Initialize `RESTInterfaceExporter` from `Application`
    public required init(_ app: Apodini.Application, _ exporterConfiguration: TopLevelExporterConfiguration = RESTExporterConfiguration()) {
        guard let castedConfiguration = dynamicCast(exporterConfiguration, to: RESTExporterConfiguration.self) else {
            fatalError("Wrong configuration type passed to exporter!")
        }
        self.app = app.vapor.app
        self.exporterConfiguration = RESTConfiguration(app.vapor.app.http.server.configuration,
                                               exporterConfiguration: castedConfiguration)
    }

    public func export<H: Handler>(_ endpoint: Endpoint<H>) {
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

    public func finishedExporting(_ webService: WebServiceModel) {
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

    public func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Vapor.Request) throws -> Type?? {
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
