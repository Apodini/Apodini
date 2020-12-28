//
// Created by Andi on 22.11.20.
//

import Foundation
@_implementationOnly import Vapor
import protocol Fluent.Database

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

struct RESTRequest: Request {
    private var parameterDecoder: (UUID) -> Codable?
    private var vaporRequest: Vapor.Request

    var eventLoop: EventLoop {
        vaporRequest.eventLoop
    }

    var description: String {
        vaporRequest.description
    }

    init(_ vaporRequest: Vapor.Request, parameterDecoder: @escaping (UUID) -> Codable?) {
        self.parameterDecoder = parameterDecoder
        self.vaporRequest = vaporRequest
    }

    func parameter<T: Codable>(for parameter: UUID) throws -> T? {
        parameterDecoder(parameter) as? T
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
        let requestHandler = endpoint.requestHandler

        routesBuilder.on(operation.httpMethod, []) { request -> EventLoopFuture<Vapor.Response> in
            let restRequest = RESTRequest(request, parameterDecoder: self.parameterDecoder(for: request))
            let response: EventLoopFuture<Encodable> = requestHandler(restRequest)

            let result = response.flatMapThrowing { (response: Encodable) -> Vapor.Response in
                let data = try JSONEncoder().encode(AnyEncodable(value: response))
                return Vapor.Response(body: .init(data: data))
            }

            return result
        }

        app.logger.info("\(operation.httpMethod.rawValue) \(pathBuilder.pathDescription)")

        for relationship in endpoint.relationships {
            let path = relationship.destinationPath
            app.logger.info("  - links to: \(StringPathBuilder(path).build())")
        }
    }

    func parameterDecoder(for request: Vapor.Request) -> (UUID) -> Codable? {
        fatalError("Not yet implemented")
    }

    func finishedExporting(_ webService: WebServiceModel) {
        if webService.rootEndpoints.isEmpty {
            // if the root path doesn't have endpoints we need to create a custom one to deliver linking entry points.

            for relationship in webService.relationships {
                app.logger.info("/ + \(HTTPMethod.GET.rawValue)")
                let path = relationship.destinationPath
                app.logger.info("  - links to: \(StringPathBuilder(path).build())")
            }
        }
    }
}
