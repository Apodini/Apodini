//
// Created by Andi on 25.12.20.
//

import class NIO.EventLoopFuture
import protocol NIO.EventLoop
import protocol FluentKit.Database

class InternalEndpointRequestHandler<I: InterfaceExporter, H: Handler> {
    private var endpoint: Endpoint<H>
    private var exporter: I

    init(endpoint: Endpoint<H>, exporter: I) {
        self.endpoint = endpoint
        self.exporter = exporter
    }

    func callAsFunction(
        request: ValidatedRequest<I, H>
    ) -> EventLoopFuture<Encodable> {
        let guardEventLoopFutures = endpoint.guards.map { guardClosure -> EventLoopFuture<Void> in
            do {
                return try request.enterRequestContext(with: guardClosure()) { requestGuard in
                    do {
                        return try requestGuard.executeGuardCheck(on: request)
                    } catch {
                        return request.eventLoop.makeFailedFuture(error)
                    }
                }
            } catch {
                return request.eventLoop.makeFailedFuture(error)
            }
        }

        return EventLoopFuture<Void>
            .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
                .flatMap { _ in
                    do {
                        return try request.enterRequestContext(with: self.endpoint.handler) { handler in
                            do {
                                var response: Encodable = handler.handle()

                                for transformer in self.endpoint.responseTransformers {
                                    response = try request.enterRequestContext(with: transformer()) { responseTransformer in
                                        responseTransformer.transform(response: response)
                                    }
                                }

                                return request.eventLoop.makeSucceededFuture(response)
                            } catch {
                                return request.eventLoop.makeFailedFuture(error)
                            }
                        }
                    } catch {
                        return request.eventLoop.makeFailedFuture(error)
                    }
                }
    }
}
