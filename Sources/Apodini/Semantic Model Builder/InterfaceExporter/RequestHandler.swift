//
// Created by Andi on 25.12.20.
//

import class NIO.EventLoopFuture
import protocol NIO.EventLoop
import struct NIO.EventLoopPromise

struct InternalEndpointRequestHandler<I: InterfaceExporter, H: Handler> {
    private let instance: EndpointInstance<H>
    private let exporter: I

    init(endpoint: EndpointInstance<H>, exporter: I) {
        self.instance = endpoint
        self.exporter = exporter
    }

    func callAsFunction(
        with validatedRequest: ValidatedRequest<I, H>,
        on connection: Connection
    ) -> EventLoopFuture<Response<HandledRequest>> {
        guard let request = connection.request else {
            fatalError("Tried to handle request without request.")
        }
        
        
        let guardEventLoopFutures = instance.guards.map { requestGuard -> EventLoopFuture<Void> in
            connection.enterConnectionContext(with: requestGuard) { requestGuard in
                requestGuard.executeGuardCheck(on: request)
            }
        }
        
        return EventLoopFuture<Void>
            .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
            .flatMapThrowing { _ in
                try connection.enterConnectionContext(with: self.instance.handler) { handler in
                    try handler.handle()
                        .transformToResponse(on: request.eventLoop)
                }
            }
            .flatMap { typedAction -> EventLoopFuture<Response<HandledRequest>> in
                let transformed = self.transformResponse(
                    typedAction.typeErasured,
                    using: connection,
                    on: request.eventLoop,
                    using: self.instance.responseTransformers)

                return transformed.map { response -> Response<HandledRequest> in
                    mapToHandledRequest(response, validatedRequest: validatedRequest)
                }
            }
    }

    private func mapToHandledRequest(_ response: Response<AnyEncodable>, validatedRequest: ValidatedRequest<I, H>) -> Response<HandledRequest> {
        response.map { anyEncodable in
            HandledRequest(
                for: instance.endpoint,
                response: anyEncodable,
                parameters: validatedRequest.validatedParameterValues)
        }
    }

    private func transformResponse(_ response: Response<AnyEncodable>,
                                   using connection: Connection,
                                   on eventLoop: EventLoop,
                                   using modifiers: [AnyResponseTransformer]) -> EventLoopFuture<Response<AnyEncodable>> {
        guard let modifier = modifiers.first else {
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
