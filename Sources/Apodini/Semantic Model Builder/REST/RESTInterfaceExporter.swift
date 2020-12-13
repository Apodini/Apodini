//
// Created by Andi on 22.11.20.
//

import Vapor

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

class RESTInterfaceExporter: InterfaceExporter {
    let app: Application

    required init(_ app: Application) {
        self.app = app
    }

    func export(_ endpoint: Endpoint) {
        let pathBuilder = RESTPathBuilder(endpoint.absolutePath)
        let routesBuilder = pathBuilder.routesBuilder(app)

        let operation = endpoint.operation
        let requestHandler = endpoint.createRequestHandler(for: self)

        routesBuilder.on(operation.httpMethod, [], use: requestHandler)

        app.logger.info("\(operation.httpMethod.rawValue) \(pathBuilder.pathDescription)")

        for relationship in endpoint.relationships {
            let path = relationship.destinationPath
            app.logger.info("  - links to: \(StringPathBuilder(path).build())")
        }
    }

    func finishedExporting(_ webService: WebServiceModel) {
        if webService.rootEndpoints.count == 0 {
            // if the root path doesn't have endpoints we need to create a custom one to deliver linking entry points.

            for relationship in webService.relationships {
                app.logger.info("/ + \(HTTPMethod.GET.rawValue)")
                let path = relationship.destinationPath
                app.logger.info("  - links to: \(StringPathBuilder(path).build())")
            }
        }
    }

    func decode<T>(_ type: T.Type, from request: Vapor.Request) throws -> T? where T: Decodable {
        print("decode")
        guard let byteBuffer = request.body.data, let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
            throw Vapor.Abort(.internalServerError, reason: "Could not read the HTTP request's body")
        }
        print("try decode")
        return try JSONDecoder().decode(type, from: data)
    }
}
