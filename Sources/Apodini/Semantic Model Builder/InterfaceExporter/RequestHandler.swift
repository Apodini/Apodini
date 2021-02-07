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
    ) -> EventLoopFuture<Response<EnrichedContent>> {
        let request = connection.request
        
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
            .flatMap { typedResponse -> EventLoopFuture<Response<EnrichedContent>> in
                let transformed = self.transformResponse(
                    typedResponse.typeErasured,
                    using: connection,
                    on: request.eventLoop,
                    using: self.instance.responseTransformers
                )

                return transformed.map { response -> Response<EnrichedContent> in
                    mapToEnrichedContent(response, validatedRequest: validatedRequest)
                }
            }
    }

    private func mapToEnrichedContent(_ response: Response<AnyEncodable>, validatedRequest: ValidatedRequest<I, H>) -> Response<EnrichedContent> {
        response.map { anyEncodable in
            EnrichedContent(
                for: instance.endpoint,
                response: anyEncodable,
                parameters: validatedRequest.validatedParameterValues
            )
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
