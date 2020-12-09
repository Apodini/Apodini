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

    func export(_ node: EndpointsTreeNode) {
        exportEndpoints(node)

        for child in node.children {
            export(child)
        }
    }

    func exportEndpoints(_ node: EndpointsTreeNode) {
        let pathBuilder = RESTPathBuilder(node.absolutePath)
        let routesBuilder = pathBuilder.routesBuilder(app)

        for (operation, endpoint) in node.endpoints {
            let requestHandler = createRequestHandler(for: endpoint)
            routesBuilder.on(operation.httpMethod, [], use: requestHandler)

            app.logger.info("\(pathBuilder.pathDescription) + \(operation.httpMethod.rawValue) with \(endpoint.guards.count) guards.")

            for linkedNode in node.children {
                let pathComponents = linkedNode.absolutePath
                app.logger.info("  - links to: \(StringPathBuilder(pathComponents).build())")
            }
        }
    }

    func createRequestHandler<ResponseType: Encodable>(for endpoint: Endpoint<ResponseType>) -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        { (request: Vapor.Request) in
            let guardEventLoopFutures = endpoint.guards.map { guardClosure in
                request.enterRequestContext(with: guardClosure()) { requestGuard in
                    requestGuard.executeGuardCheck(on: request)
                }
            }
            return EventLoopFuture<Void>
                    .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
                    .flatMap { _ in
                        request.enterRequestContext(with: endpoint) { endpoint in
                            var response: ResponseType = endpoint.handleMethod()

                            for responseTransformer in endpoint.responseTransformers {
                                response = request.enterRequestContext(with: responseTransformer()) { responseTransformer in
                                    responseTransformer.transform(response: response) as! ResponseType
                                }
                            }
                            let vaporResponse = try! Vapor.Response(encoding: response)
                            return request.eventLoop.makeSucceededFuture(vaporResponse)
                        }
                    }
        }
    }
}
