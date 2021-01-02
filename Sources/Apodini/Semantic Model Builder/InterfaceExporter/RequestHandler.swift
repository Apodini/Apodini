//
// Created by Andi on 25.12.20.
//

import class NIO.EventLoopFuture
import protocol NIO.EventLoop
import protocol FluentKit.Database

class EndpointRequestHandler<I: InterfaceExporter> {
    func callAsFunction(request: I.ExporterRequest, eventLoop: EventLoop) -> EventLoopFuture<Encodable> {
        // We are doing nothing here. Everything is handled in InternalEndpointRequestHandler
        fatalError("EndpointRequestHandler.handleRequest() was not overridden. EndpointRequestHandler must not be created manually!")
    }
}

extension EndpointRequestHandler where I.ExporterRequest: WithEventLoop {
    func callAsFunction(request: I.ExporterRequest) -> EventLoopFuture<Encodable> {
        callAsFunction(request: request, eventLoop: request.eventLoop)
    }
}

class InternalEndpointRequestHandler<I: InterfaceExporter, H: Handler>: EndpointRequestHandler<I> {
    private var endpoint: Endpoint<H>
    private var exporter: I

    init(endpoint: Endpoint<H>, exporter: I) {
        self.endpoint = endpoint
        self.exporter = exporter
    }

    override func callAsFunction(request exporterRequest: I.ExporterRequest, eventLoop: EventLoop) -> EventLoopFuture<Encodable> {
        let request = ApodiniRequest(for: exporter, with: exporterRequest, on: endpoint, running: eventLoop)

        let guardEventLoopFutures = endpoint.guards.map { guardClosure in
            request.enterRequestContext(with: guardClosure()) { requestGuard in
                requestGuard.executeGuardCheck(on: request)
            }
        }

        return EventLoopFuture<Void>
            .whenAllSucceed(guardEventLoopFutures, on: eventLoop)
            .flatMap { _ in
                request.enterRequestContext(with: self.endpoint.handler) { handler in
                    var response: Encodable = handler.handle()
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
