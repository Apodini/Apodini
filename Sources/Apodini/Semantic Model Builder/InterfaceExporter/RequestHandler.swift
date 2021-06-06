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
        
        return request.eventLoop.makeSucceededVoidFuture()
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
            .map { (typedResponse: Response<H.Response.Content>) -> Response<EnrichedContent> in
                mapToEnrichedContent(typedResponse.typeErasured, validatedRequest: validatingRequest)
            }
    }

    private func mapToEnrichedContent(_ response: Response<AnyEncodable>, validatedRequest: ValidatingRequest<I, H>) -> Response<EnrichedContent> {
        response.map { anyEncodable in
            EnrichedContent(
                for: instance.endpoint,
                response: anyEncodable,
                parameters: { uuid in try? validatedRequest.retrieveAnyParameter(uuid) }
            )
        }
    }
}
