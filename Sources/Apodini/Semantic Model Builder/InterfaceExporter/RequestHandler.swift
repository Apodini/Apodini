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
        with request: Request,
        on connection: Connection
    ) -> EventLoopFuture<Response<H.Response.Content>> {
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
    }
}
