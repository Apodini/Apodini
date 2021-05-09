//
// Created by Andreas Bauer on 22.11.20.
//

import Apodini
import Vapor
import NIO

extension Vapor.Request: ExporterRequest, WithEventLoop, WithRemote {}

/// Apodini Interface Exporter for REST.
public final class RESTInterfaceExporter: InterfaceExporter {
    public static let parameterNamespace: [ParameterNamespace] = .individual

    let app: Vapor.Application
    let configuration: RESTConfiguration

    /// Initialize `RESTInterfaceExporter` from `Application`
    public required init(_ app: Apodini.Application) {
        self.app = app.vapor.app
        self.configuration = RESTConfiguration(app.vapor.app.http.server.configuration)
    }

    public func export<H: Handler>(_ endpoint: Endpoint<H>) {
        var pathBuilder = RESTPathBuilder()
        endpoint.absolutePath.build(with: &pathBuilder)

        let routesBuilder = pathBuilder.routesBuilder(app)

        let operation = endpoint[Operation.self]

        let endpointHandler = RESTEndpointHandler(with: configuration, for: endpoint, on: self)
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

            let handler = RESTDefaultRootHandler(configuration: configuration, relationships: relationships)
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
            return try? request.content.decode(Type.self, using: JSONDecoder())

        case .header:
            return request.headers.first(name: parameter.name) as? Type
        }
    }
}
