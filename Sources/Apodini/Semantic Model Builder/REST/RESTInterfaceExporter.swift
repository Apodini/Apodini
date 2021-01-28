//
// Created by Andi on 22.11.20.
//

@_implementationOnly import Vapor

extension Vapor.Request: ExporterRequest, WithEventLoop {}

class RESTInterfaceExporter: InterfaceExporter {
    static let parameterNamespace: [ParameterNamespace] = .individual

    let app: Vapor.Application
    let configuration: RESTConfiguration

    required init(_ app: Apodini.Application) {
        self.app = app.vapor.app
        self.configuration = RESTConfiguration(app.vapor.app.http.server.configuration)
    }

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        var pathBuilder = RESTPathBuilder()
        endpoint.absolutePath.build(with: &pathBuilder)

        let routesBuilder = pathBuilder.routesBuilder(app)

        let operation = endpoint.operation

        let exportedParameterNames = endpoint.exportParameters(on: self)

        let endpointHandler = RESTEndpointHandler(configuration: configuration, using: { endpoint.createConnectionContext(for: self) })
        endpointHandler.register(at: routesBuilder, with: operation)

        app.logger.info("Exported '\(Vapor.HTTPMethod(operation).rawValue) \(pathBuilder.pathDescription)' with parameters: \(exportedParameterNames)")

        if endpoint.inheritsRelationship {
            app.logger.info("  - inherits from: \(endpoint.selfRelationship.destinationPath.asPathString())")
        }

        for destination in endpoint.relationship(for: .read) {
            let path = destination.destinationPath
            app.logger.info("  - links to: \(path.asPathString())")
        }
    }

    func exportParameter<Type: Codable>(_ parameter: EndpointParameter<Type>) -> String {
        // This is currently just a example on how one can use the exportParameter method
        // The return type can be whatever you want
        parameter.name
    }

    func finishedExporting(_ webService: WebServiceModel) {
        if webService.getEndpoint(for: .read) == nil {
            // if the root path doesn't have a read endpoint we need to create a custom one to deliver linking entry points.

            let relationships = webService.relationships(for: .read)

            let handler = RESTDefaultRootHandler(configuration: configuration, relationships: relationships)
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
            return try? request.content.decode(Type.self, using: JSONDecoder())
        }
    }
}
