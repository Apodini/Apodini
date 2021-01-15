//
// Created by Andi on 22.11.20.
//

import Foundation
@_implementationOnly import Vapor

struct RESTPathBuilder: PathBuilder {
    private var pathComponents: [Vapor.PathComponent] = []
    private var pathString: [String] = []
    fileprivate var pathDescription: String {
        pathString.joined(separator: "/")
    }

    mutating func append(_ string: String) {
        let pathComponent = string.lowercased()
        pathComponents.append(.constant(pathComponent))
        pathString.append(pathComponent)
    }

    mutating func root() {
        pathString.append("")
    }

    mutating func append<Type>(_ parameter: EndpointPathParameter<Type>) {
        pathComponents.append(.parameter(parameter.pathId))
        pathString.append("{\(parameter.name)}")
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

struct RESTConfiguration {
    let configuration: HTTPServer.Configuration
    let bindAddress: BindAddress
    let uriPrefix: String

    init(_ configuration: HTTPServer.Configuration) {
        self.configuration = configuration
        self.bindAddress = configuration.address

        switch bindAddress {
        case .hostname:
            let httpProtocol: String
            var port = ""

            if configuration.tlsConfiguration == nil {
                httpProtocol = "http://"
                if configuration.port != 80 {
                    port = ":\(configuration.port)"
                }
            } else {
                httpProtocol = "https://"
                if configuration.port != 443 {
                    port = ":\(configuration.port)"
                }
            }

            self.uriPrefix = httpProtocol + configuration.hostname + port
        case let .unixDomainSocket(path):
            self.uriPrefix = path
        }
    }
}

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

        let endpointHandler = RESTEndpointHandler(for: endpoint, using: { endpoint.createConnectionContext(for: self) }, configuration: configuration)
        endpointHandler.register(at: routesBuilder, with: operation)

        app.logger.info("Exported '\(operation.httpMethod.rawValue) \(pathBuilder.pathDescription)' with parameters: \(exportedParameterNames)")

        for relationship in endpoint.relationships {
            let path = relationship.destinationPath
            app.logger.info("  - links to: \(path.asPathString())")
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
                app.logger.info("  - links to: \(path.asPathString())")
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

            return try request.content.decode(Type.self, using: JSONDecoder())
        }
    }
}
