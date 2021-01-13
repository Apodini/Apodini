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
    func createClientStreamingHandler(contextCreator: @escaping () -> AnyConnectionContext<GRPCInterfaceExporter>)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        { (request: Vapor.Request) in
            if !self.checkContentType(request: request) {
                return request.eventLoop.makeFailedFuture(GRPCError.unsupportedContentType(
                    "Content type is currently not supported by Apodini GRPC exporter. Use Protobuffers instead."
                ))
            }

            let promise = request.eventLoop.makePromise(of: Vapor.Response.self)
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
                        // For now we only support messages delivered in one
                        // frame, and multiple messages delivered in one frame.
                        // One message delivered in multiple messages is not yet supported.
                        // See `getMessages` internal comments for more details.
                        .filter({ $0.isComplete })
                        .forEach({ message in
                            // each message delivers all necessary values in GRPC
                            // so we need a new context for each message, to avoid
                            // errors for redefining constants
                            var context = contextCreator()
                            // Discard any result that is received back from the handler;
                            // this is a client-streaming handler, thus we only send back
                            // a response in the .end case.
                            _ = context.handle(request: message, eventLoop: request.eventLoop, final: false)
                        })
                case .end:
                    // send the previously retained lastMessage through the handler
                    // and set the final flag
                    var context = contextCreator()
                    let message = lastMessage ?? GRPCMessage.DefaultMessage
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
            return promise.futureResult
        }
    }

    /// Exposes a client streaming endpoint for the handle that the service was initialized with.
    /// The endpoint will be accessible at [host]/[serviceName]/[endpoint].
    /// - Parameters:
    ///     - endpoint: The name of the endpoint that should be exposed.
    func exposeClientStreamingEndpoint(name endpoint: String,
                                       contextCreator: @escaping () -> AnyConnectionContext<GRPCInterfaceExporter>) {
        let path = [
            Vapor.PathComponent(stringLiteral: serviceName),
            Vapor.PathComponent(stringLiteral: endpoint)
        ]

        app.on(.POST, path) { request in
            self.createClientStreamingHandler(contextCreator: contextCreator)(request)
        }
    }
}
