//
// Created by Andi on 25.12.20.
//

import class NIO.EventLoopFuture
import protocol NIO.EventLoop

class EndpointRequestHandler<I: InterfaceExporter> {
    func handleRequest(request: I.ExporterRequest, eventLoop: EventLoop) -> EventLoopFuture<Encodable> {
        // We are doing nothing here. Everything is handled in InternalEndpointRequestHandler
        fatalError("EndpointRequestHandler.handleRequest() was not overridden. EndpointRequestHandler must not be created manually!")
    }
}

extension EndpointRequestHandler where I.ExporterRequest: WithEventLoop {
    func handleRequest(request: I.ExporterRequest) -> EventLoopFuture<Encodable> {
        handleRequest(request: request, eventLoop: request.eventLoop)
    }
}

class InternalEndpointRequestHandler<I: InterfaceExporter, C: Component>: EndpointRequestHandler<I> {
    private var endpoint: Endpoint<C>
    private var exporter: I

    init(endpoint: Endpoint<C>, exporter: I) {
        self.endpoint = endpoint
        self.exporter = exporter
    }

    override func handleRequest(request exporterRequest: I.ExporterRequest, eventLoop: EventLoop) -> EventLoopFuture<Encodable> {
        let request = ApodiniRequest(for: exporter, with: exporterRequest, on: endpoint, running: eventLoop)

        let guardEventLoopFutures = endpoint.guards.map { guardClosure in
            request.enterRequestContext(with: guardClosure()) { requestGuard in
                requestGuard.executeGuardCheck(on: request)
            }
        }

        return EventLoopFuture<Void>
                .whenAllSucceed(guardEventLoopFutures, on: eventLoop)
                .flatMap { _ in
                    request.enterRequestContext(with: self.endpoint.component) { component in
                        var response: Encodable = component.handle()

                        for transformer in self.endpoint.responseTransformers {
                            response = request.enterRequestContext(with: transformer()) { responseTransformer in
                                responseTransformer.transform(response: response)
                            }
                        }

                        return eventLoop.makeSucceededFuture(response)
                    }
                }
    }
}
