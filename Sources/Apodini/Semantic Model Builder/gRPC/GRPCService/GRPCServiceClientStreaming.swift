//
//  GRPCServiceClientStreaming.swift
//  
//
//  Created by Moritz Schüll on 07.01.21.
//

import Foundation
@_implementationOnly import Vapor

private enum GRPCMessageResponse {
    case response(_ response: Vapor.Response)
    case last(_ response: Vapor.Response)
    case error(_ error: Error)
}

// MARK: Client streaming request handler
extension GRPCService {
    private func drainClientStream<C: ConnectionContext>(from request: Vapor.Request,
                                                         using context: C,
                                                         promise: EventLoopPromise<Vapor.Response>? = nil,
                                                         responseStream: BodyStreamWriter? = nil,
                                                         _ callback: @escaping (GRPCMessageResponse, EventLoopPromise<Void>) -> Void)
    where C.Exporter == GRPCInterfaceExporter {
        var context = context
        var lastMessage: GRPCMessage?
        request.body.drain { (bodyStream: BodyStreamResult) in
            let responsePromise = request.eventLoop.makePromise(of: Void.self)
            switch bodyStream {
            case let .buffer(byteBuffer):
                guard let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
                    return request.eventLoop.makeFailedFuture(GRPCError.payloadReadError("Cannot read byte-buffer from fragment"))
                }

                // retrieve all GRPC messages that were delivered in this request
                // (may be none, one or multiple)
                var messages = self.getMessages(from: data)
                // prepend previously retained last message
                messages.prepend(lastMessage, at: 0)
                // retain the last message, to run it through the handler
                // once the .end message was received.
                lastMessage = messages.popLast()

                if messages.count == 0 {
                    responsePromise.succeed(())
                }

                messages
                    // For now we only support
                    // - one message delivered in one frame,
                    // - multiple messages delivered in one frame.
                    // One message delivered in multiple frames is not yet supported.
                    // See `getMessages` internal comments for more details.
                    .filter(\.didCollectAllFragments)
                    .forEach { message in
                        let response = context.handle(request: message, eventLoop: request.eventLoop, final: false)
                        response.whenFailure { callback(.error($0), responsePromise) }
                        response.whenSuccess { response in
                            let response = self.makeResponse(response)
                            callback(.response(response), responsePromise)
                        }
                    }
            case .end:
                // send the previously retained lastMessage through the handler
                // and set the final flag
                let message = lastMessage ?? GRPCMessage.defaultMessage
                let response = context.handle(request: message, eventLoop: request.eventLoop, final: true)
                response.whenFailure { callback(.error($0), responsePromise) }
                response.whenSuccess { response in
                    let response = self.makeResponse(response)
                    callback(.last(response), responsePromise)
                }
            case let .error(error):
                callback(.error(error), responsePromise)
            }

            return responsePromise.futureResult
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
            self.drainClientStream(from: request, using: context) { response, responsePromise in
                responsePromise.succeed(())
                switch response {
                case .response(_):
                    // Discard any result that is received back from the handler if no service stream was handed over.
                    // In that case, this is a client-streaming handler, thus we only send back a response in the .end case.
                    break
                case let .last(message):
                    let response = request.eventLoop.makeSucceededFuture(message)
                    promise.completeWith(response)
                case let .error(err):
                    promise.fail(err)
                }
            }
            return promise.futureResult
        }
    }

    func createBidirectionalStreamingHandler<C: ConnectionContext>(context: C)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> where C.Exporter == GRPCInterfaceExporter {
        { (request: Vapor.Request) in
            if !self.contentTypeIsSupported(request: request) {
                return request.eventLoop.makeFailedFuture(GRPCError.unsupportedContentType(
                    "Content type is currently not supported by Apodini GRPC exporter. Use Protobuffers instead."
                ))
            }

            let streamingResponse: (BodyStreamWriter) -> () = { writer in
                self.drainClientStream(from: request, using: context) { response, responsePromise in
                    switch response {
                    case let .response(message):
                        if let buffer = message.body.buffer {
                            writer.write(.buffer(buffer), promise: responsePromise)
                        }
                    case let .last(message):
                        if let buffer = message.body.buffer {
                            writer.write(.buffer(buffer), promise: responsePromise)
                            writer.write(.end, promise: responsePromise)
                        }
                    case let .error(err):
                        writer.write(.error(err), promise: responsePromise)
                    }
                }
            }

            let response = self.makeResponse(streamingResponse)
            return request.eventLoop.makeSucceededFuture(response)
        }
    }

    /// Exposes a client streaming endpoint for the handle that the service was initialized with.
    /// The endpoint will be accessible at [host]/[serviceName]/[endpoint].
    /// - Parameters:
    ///     - endpoint: The name of the endpoint that should be exposed.
    func exposeStreamingEndpoint<C: ConnectionContext>(name endpoint: String,
                                                       context: C,
                                                       bidirectional: Bool = false)
    throws where C.Exporter == GRPCInterfaceExporter {
        if methodNames.contains(endpoint) {
            throw GRPCServiceError.endpointAlreadyExists
        }
        methodNames.append(endpoint)

        let path = [
            Vapor.PathComponent(stringLiteral: serviceName),
            Vapor.PathComponent(stringLiteral: endpoint)
        ]

        app.on(.POST, path, body: .stream) { request -> EventLoopFuture<Vapor.Response> in
            if bidirectional {
                return self.createBidirectionalStreamingHandler(context: context)(request)
            } else {
                return self.createClientStreamingHandler(context: context)(request)
            }
        }
    }
}

extension Array {
    mutating func prepend(_ newElement: Self.Element?, at i: Int) {
        if let element = newElement {
            self.insert(element, at: i)
        }
    }
}
