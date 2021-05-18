//
// Created by Andreas Bauer on 25.12.20.
//

import class NIO.EventLoopFuture
import protocol NIO.EventLoop
import struct NIO.EventLoopPromise
import ApodiniUtils

struct InternalEndpointRequestHandler<I: InterfaceExporter, H: Handler> {
    private let instance: EndpointInstance<H>
    private let exporter: I

    init(endpoint: EndpointInstance<H>, exporter: I) {
        self.instance = endpoint
        self.exporter = exporter
    }

    func callAsFunction(
        with validatingRequest: ValidatingRequest<I, H>,
        on connection: Connection
    ) -> EventLoopFuture<Response<EnrichedContent>> {
        let request = connection.request
        
        let guardEventLoopFutures = instance.guards.map { requestGuard -> EventLoopFuture<Void> in
            do {
                return try connection.enterConnectionContext(with: requestGuard) { requestGuard in
                    requestGuard.executeGuardCheck(on: request)
                }
            } catch {
                return connection.eventLoop.makeFailedFuture(error)
            }
        }
        
        return EventLoopFuture<Void>
            .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
            .flatMapThrowing { _ in
                do {
                    return try connection.enterConnectionContext(with: self.instance.handler) { handler in
                        handler.evaluate(using: request.eventLoop)
                            .transformToResponse(on: request.eventLoop)
                    }
                } catch {
                    return connection.eventLoop.makeFailedFuture(error)
                }
            }
            .flatMap { (typedResponse: Response<H.Response.Content>) -> EventLoopFuture<Response<EnrichedContent>> in
                let transformed = self.transformResponse(
                    typedResponse.typeErasured,
                    using: connection,
                    on: request.eventLoop,
                    using: self.instance.responseTransformers
                )

                return transformed.map { response -> Response<EnrichedContent> in
                    mapToEnrichedContent(response, validatedRequest: validatingRequest)
                }
            }
    }

    private func mapToEnrichedContent(_ response: Response<AnyEncodable>, validatedRequest: ValidatingRequest<I, H>) -> Response<EnrichedContent> {
        response.map { anyEncodable in
            EnrichedContent(
                for: instance.endpoint,
                response: anyEncodable,
                parameters: { uuid in
                    try? validatedRequest.retrieveAnyParameter(uuid) }
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
        
        do {
            return try connection
                .enterConnectionContext(with: modifier) { responseTransformerInContext in
                    responseTransformerInContext.transform(response: response, on: eventLoop)
                }
                .flatMap { newResponse in
                    self.transformResponse(newResponse, using: connection, on: eventLoop, using: Array(modifiers.dropFirst()))
                }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}
