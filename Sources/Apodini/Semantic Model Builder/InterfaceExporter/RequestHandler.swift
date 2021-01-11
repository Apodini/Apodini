//
// Created by Andi on 25.12.20.
//

import class NIO.EventLoopFuture
import protocol NIO.EventLoop
import struct NIO.EventLoopPromise

class InternalEndpointRequestHandler<I: InterfaceExporter, H: Handler> {
    private var endpoint: Endpoint<H>
    private var exporter: I

    init(endpoint: Endpoint<H>, exporter: I) {
        self.endpoint = endpoint
        self.exporter = exporter
    }

    func callAsFunction(
        on connection: Connection
    ) -> EventLoopFuture<Response<AnyEncodable>> {
        guard let request = connection.request else {
            fatalError("Tried to handle request without request.")
        }
        
        
        let guardEventLoopFutures = endpoint.guards.map { guardClosure -> EventLoopFuture<Void> in
            connection.enterConnectionContext(with: guardClosure()) { requestGuard in
                requestGuard.executeGuardCheck(on: request)
            }
        }
        
        return EventLoopFuture<Void>
            .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
            .flatMap { _ in
                connection.enterConnectionContext(with: self.endpoint.handler) { handler in
                    handler.handle()
                        .transformToResponse(on: request.eventLoop)
                }
            }
            .flatMap { typedAction -> EventLoopFuture<Response<AnyEncodable>> in
                self.transformResponse(typedAction.typeErasured, using: connection, on: request.eventLoop, using: self.endpoint.responseTransformers)
            }
    }

    private func transformResponse(_ response: Response<AnyEncodable>,
                                   using connection: Connection,
                                   on eventLoop: EventLoop,
                                   using modifiers: [LazyAnyResponseTransformer]) -> EventLoopFuture<Response<AnyEncodable>> {
        guard let modifier = modifiers.first?() else {
            return eventLoop.makeSucceededFuture(response)
        }
        
        return connection
            .enterConnectionContext(with: modifier) { responseTransformerInContext in
                responseTransformerInContext.transform(response: response, on: eventLoop)
            }
            .flatMap { newResponse in
                self.transformResponse(newResponse, using: connection, on: eventLoop, using: Array(modifiers.dropFirst()))
            }
    }
}
