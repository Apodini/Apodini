//
// Created by Andi on 30.12.20.
//

@_implementationOnly import Vapor

struct RESTEndpointHandler {
    var contextCreator: () -> ConnectionContext<RESTInterfaceExporter>
    let configuration: RESTConfiguration

    init(configuration: RESTConfiguration, using contextCreator: @escaping () -> ConnectionContext<RESTInterfaceExporter>) {
        self.configuration = configuration
        self.contextCreator = contextCreator
    }

    func register(at routesBuilder: Vapor.RoutesBuilder, with operation: Operation) {
        routesBuilder.on(Vapor.HTTPMethod(operation), [], use: self.handleRequest)
    }

    func handleRequest(request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        let context = contextCreator()

        let responseFuture = context.handle(request: request)

        return responseFuture.flatMap { (encodableAction: Response<HandledRequest>) in
            switch encodableAction {
            case let .send(response),
                 let .final(response):

                let formatter = LinksFormatter(configuration: self.configuration)
                var links = response.formatRelationships(
                    into: [:],
                    with: formatter,
                    for: .read)
                response.formatSelfRelationship(into: &links, with: formatter)

                let container = ResponseContainer(response.response, links: links)
                return container.encodeResponse(for: request)
            case .nothing, .end:
                return request.eventLoop.makeSucceededFuture(Vapor.Response(status: .noContent))
            }
        }
    }
}
