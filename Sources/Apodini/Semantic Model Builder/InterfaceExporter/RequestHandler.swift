//
// Created by Andi on 25.12.20.
//

import class NIO.EventLoopFuture
import protocol NIO.EventLoop
import struct NIO.EventLoopPromise

class EndpointRequestHandler<I: InterfaceExporter> {
    func callAsFunction(request: I.ExporterRequest, eventLoop: EventLoop) -> EventLoopFuture<Action<AnyEncodable>> {
        // We are doing nothing here. Everything is handled in InternalEndpointRequestHandler
        fatalError("EndpointRequestHandler.handleRequest() was not overridden. EndpointRequestHandler must not be created manually!")
    }
}

extension EndpointRequestHandler where I.ExporterRequest: WithEventLoop {
    func callAsFunction(request: I.ExporterRequest) -> EventLoopFuture<Action<AnyEncodable>> {
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

    override func callAsFunction(request exporterRequest: I.ExporterRequest, eventLoop: EventLoop) -> EventLoopFuture<Action<AnyEncodable>> {
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
                    handler.handle()
                        .action(on: request.eventLoop)
                }
            }
            .flatMap { typedAction -> EventLoopFuture<Action<AnyEncodable>> in
                self.transformResponse(typedAction.typeErasured, on: request, using: self.endpoint.responseTransformers)
            }
    }
    

    private func transformResponse(_ response: Action<AnyEncodable>,
                                   on request: Request,
                                   using modifiers: [() -> (AnyResponseTransformer)]) -> EventLoopFuture<Action<AnyEncodable>> {
        guard let modifier = modifiers.first?() else {
            return request.eventLoop.makeSucceededFuture(response)
        }

        return request
            .enterRequestContext(with: modifier) { responseTransformerInContext in
                responseTransformerInContext.transform(response: response, on: request.eventLoop)
            }
            .flatMap { newResponse in
                self.transformResponse(newResponse, on: request, using: Array(modifiers.dropFirst()))
            }
    }
}
