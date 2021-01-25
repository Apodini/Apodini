//
//  GRPCServiceClientStreaming.swift
//  
//
//  Created by Moritz Schüll on 07.01.21.
//

import Foundation
@_implementationOnly import Vapor

// MARK: Client streaming request handler
extension GRPCService {
    private func drainBody<C: ConnectionContext>(from request: Vapor.Request,
                                                 using context: C,
                                                 promise: EventLoopPromise<Vapor.Response>)
    where C.Exporter == GRPCInterfaceExporter {
        var context = context
        var lastMessage: GRPCMessage?
        request.body.drain { (bodyStream: BodyStreamResult) in
            switch bodyStream {
            case let .buffer(byteBuffer):
                guard let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
                    return request.eventLoop.makeFailedFuture(GRPCError.payloadReadError("Cannot read byte-buffer from fragment"))
                }

                // retrieve all GRPC messages that were delivered in this request
                // (may be none, one or multiple)
                var messages = self.getMessages(from: data)
                // retain the last message, to run it through the handler
                // once the .end message was received.
                lastMessage = messages.popLast()

                messages
                    // For now we only support
                    // - one message delivered in one frame,
                    // - multiple messages delivered in one frame.
                    // One message delivered in multiple frames is not yet supported.
                    // See `getMessages` internal comments for more details.
                    .filter(\.didCollectAllFragments)
                    .forEach({ message in
                        // Discard any result that is received back from the handler.
                        // This is a client-streaming handler, thus we only send back
                        // a response in the .end case.
                        _ = context.handle(request: message, eventLoop: request.eventLoop, final: false)
                    })
            case .end:
                // send the previously retained lastMessage through the handler
                // and set the final flag
                let message = lastMessage ?? GRPCMessage.defaultMessage
                let response = context.handle(request: message, eventLoop: request.eventLoop, final: true)
                let result = response.map { encodableAction -> Vapor.Response in
                    switch encodableAction {
                    case let .send(element),
                         let .final(element):
                        return self.makeResponse(element)
                    case .nothing, .end:
                        return self.makeResponse()
                    }
                }

                promise.completeWith(result)
            case let .error(error):
                return request.eventLoop.makeFailedFuture(error)
            }

            return request.eventLoop.makeSucceededFuture(())
        }
    }

    func createClientStreamingHandler<C: ConnectionContext>(context: C)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> where C.Exporter == GRPCInterfaceExporter {
        { (request: Vapor.Request) in
            if !self.contentTypeIsSupported(request: request) {
                return request.eventLoop.makeFailedFuture(GRPCError.unsupportedContentType(
                    "Content type is currently not supported by Apodini GRPC exporter. Use Protobuffers instead."
                ))
            }

            let promise = request.eventLoop.makePromise(of: Vapor.Response.self)
            self.drainBody(from: request, using: context, promise: promise)
            return promise.futureResult
        }
    }

    /// Exposes a client streaming endpoint for the handle that the service was initialized with.
    /// The endpoint will be accessible at [host]/[serviceName]/[endpoint].
    /// - Parameters:
    ///     - endpoint: The name of the endpoint that should be exposed.
    func exposeClientStreamingEndpoint<C: ConnectionContext>(name endpoint: String,
                                                             context: C) throws where C.Exporter == GRPCInterfaceExporter {
        if methodNames.contains(endpoint) {
            throw GRPCServiceError.endpointAlreadyExists
        }
        methodNames.append(endpoint)

        let path = [
            Vapor.PathComponent(stringLiteral: serviceName),
            Vapor.PathComponent(stringLiteral: endpoint)
        ]

        app.on(.POST, path) { request in
            self.createClientStreamingHandler(context: context)(request)
        }
    }
}
