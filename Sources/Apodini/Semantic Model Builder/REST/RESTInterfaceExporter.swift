//
// Created by Andi on 22.11.20.
//

import Foundation
@_implementationOnly import Vapor
import protocol FluentKit.Database

struct RESTPathBuilder: PathBuilder {
    private var pathComponents: [Vapor.PathComponent] = []


    fileprivate var pathDescription: String {
        pathComponents
                .map { pathComponent in
                    pathComponent.description
                }
                .joined(separator: "/")
    }


    init(_ pathComponents: [PathComponent]) {
        for pathComponent in pathComponents {
            if let pathComponent = pathComponent as? _PathComponent {
                pathComponent.append(to: &self)
            }
        }
    }


    mutating func append(_ string: String) {
        let pathComponent = string.lowercased()
        pathComponents.append(.constant(pathComponent))
    }

    mutating func append<T>(_ parameter: Parameter<T>) {
        let pathComponent = parameter.description
        pathComponents.append(.parameter(pathComponent))
    }

    func routesBuilder(_ app: Vapor.Application) -> Vapor.RoutesBuilder {
        app.routes.grouped(pathComponents)
    }
}


extension Operation {
    var httpMethod: Vapor.HTTPMethod {
        switch self {
        case .automatic: // a future implementation will have some sort of inference algorithm
            return .GET // for now we just use the default GET http method
        case .create:
            return .POST
        case .read:
            return .GET
        case .update:
            return .PUT
        case .delete:
            return .DELETE
        }
    }
}

extension Vapor.Request: ExporterRequest, WithEventLoop, WithDatabase {
    var database: () -> Database {{
        self.db
    }}
}

class RESTInterfaceExporter: InterfaceExporter {
    let app: Application

    required init(_ app: Application) {
        self.app = app
    }

    func export<C: Component>(_ endpoint: Endpoint<C>) {
        let pathBuilder = RESTPathBuilder(endpoint.absolutePath)
        let routesBuilder = pathBuilder.routesBuilder(app)

        let operation = endpoint.operation

        let exportedParameterNames = endpoint.exportParameters(on: self)

        let requestHandler = endpoint.createRequestHandler(for: self)

        routesBuilder.on(operation.httpMethod, []) { (request: Vapor.Request) -> EventLoopFuture<Vapor.Response> in
            let responseFuture = requestHandler.handleRequest(request: request)

            return responseFuture.flatMap { encodable in
                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]
                #warning("We may remove JSONEncoder .prettyPrinted in production or make it configurable in some way")

                let response = Response()
                do {
                    try response.content.encode(AnyEncodable(value: encodable), using: jsonEncoder)
                } catch {
                    return request.eventLoop.makeFailedFuture(error)
                }
                return request.eventLoop.makeSucceededFuture(response)
            }
        }

        app.logger.info("Exported '\(operation.httpMethod.rawValue) \(pathBuilder.pathDescription)' with parameters: \(exportedParameterNames)")

        for relationship in endpoint.relationships {
            let path = relationship.destinationPath
            app.logger.info("  - links to: \(StringPathBuilder(path).build())")
        }
    }

    func exportParameter<Type: Codable>(_ parameter: EndpointParameter<Type>) -> String {
        // This is currently just a example on how one can use the exportParameter method
        // The return type can be whatever you want
        parameter.name
    }

    func finishedExporting(_ webService: WebServiceModel) {
        if webService.rootEndpoints.isEmpty {
            // if the root path doesn't have endpoints we need to create a custom one to deliver linking entry points.

            for relationship in webService.relationships {
                app.logger.info("Auto exported '\(HTTPMethod.GET.rawValue) /'")
                let path = relationship.destinationPath
                app.logger.info("  - links to: \(StringPathBuilder(path).build())")
            }
        }
    }

    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Vapor.Request) throws -> Any?? {
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
            guard let losslessStringParameter = parameter as? LosslessStringConvertibleEndpointParameter else {
                #warning("Must be replaced with a proper error to encode a response to the user")
                fatalError("Encountered .path Parameter which isn't type of LosslessStringConvertible!")
            }

            guard let value = losslessStringParameter.initFromDescription(description: stringParameter, type: Type.self) else {
                #warning("Must be replaced with a proper error to encode a response to the user")
                fatalError("""
                           Parsed a .path Parameter, but encountered invalid format when initializing LosslessStringConvertible!
                           Could not init \(Type.self) for string value '\(stringParameter)'
                           """)
            }
            return value
        case .content:
            guard request.body.data != nil else {
                // If the request doesn't have a body, there is nothing to decide.
                return nil
            }

            #warning("""
                     A Handler could define multiple .content Parameters. In such a case the REST exporter would
                     need to decode the content via a struct containing those .content parameters as properties.
                     This is currently unsupported.
                     """)

            return try request.content.decode(Type.self, using: JSONDecoder())
        }
    }
}
