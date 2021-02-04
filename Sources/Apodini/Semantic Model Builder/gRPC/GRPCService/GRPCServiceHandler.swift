//
//  GRPCServiceClientStreaming.swift
//  
//
//  Created by Moritz Schüll on 07.01.21.
//

import Foundation
@_implementationOnly import Vapor
@_implementationOnly import OpenCombine

/// Taken & adapted from WebSocketExporter.
/// Used to differentiate between messages from the client and from observations.
private enum Evaluation {
    case input(_: GRPCMessage)
    case observation(_: AnyObservedObject)
    case end
}

/// Taken from WebSocketExporter.
private struct GRPCObservedListener: ObservedListener {
    var eventLoop: EventLoop
    var callback: (AnyObservedObject) -> Void

    func onObservedDidChange(_ observedObject: AnyObservedObject, in context: ConnectionContext<GRPCInterfaceExporter>) {
        callback(observedObject)
    }

    init(eventLoop: EventLoop, callback: @escaping (AnyObservedObject) -> Void) {
        self.eventLoop = eventLoop
        self.callback = callback
    }
}

// MARK: Client request handler
extension GRPCService {
    /// Drains a client-stream from the given `Vapor.Request`.
    /// This is also used for unary client-requests (i.e. for unary and service-streaming endpoints),
    /// since in that case the clients "stream" will just be a data frame directly followed by an .end frame.
    private func drainClientStream(from request: Vapor.Request,
                                   _ callback: @escaping (Evaluation) -> Void) {
        request.body.drain { (bodyStream: BodyStreamResult) in
            switch bodyStream {
            case let .buffer(byteBuffer):
                // A data frame was received from the client-stream.
                guard let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
                    return request.eventLoop.makeFailedFuture(GRPCError.payloadReadError("Cannot read byte-buffer from fragment"))
                }

                // retrieve all GRPC messages that were delivered in this request
                // (may be none, one or multiple)
                let messages = self.getMessages(from: data)
                for message in messages where message.didCollectAllFragments {
                    callback(.input(message))
                }
            case .end:
                // This was the last frame on this client-stream.
                callback(.end)
            case let .error(error):
                return request.eventLoop.makeFailedFuture(error)
            }

            return request.eventLoop.makeSucceededFuture(())
        }
    }

    /// Writes the `Response` to the given `BodyStreamWriter`, if the responses element is not nil.
    private func write(_ response: Response<EnrichedContent>, to stream: BodyStreamWriter, promise: EventLoopPromise<Void>? = nil) {
        if let element = response.element?.response,
           let data = self.encode(element) {
            let buffer = ByteBuffer(data: data)
            stream.write(.buffer(buffer), promise: promise)
        }
    }

    private func handleCompletion(request: Vapor.Request,
                                  context: inout ConnectionContext<GRPCInterfaceExporter>,
                                  responseWriter: BodyStreamWriter,
                                  serviceStreaming: Bool,
                                  lastMessage: GRPCMessage) {
        if serviceStreaming {
            responseWriter.write(.end, promise: nil)
        } else {
            context
                .handle(request: lastMessage, eventLoop: request.eventLoop, final: true)
                .whenComplete { result in
                    switch result {
                    case let .success(response):
                        self.write(response, to: responseWriter)
                        responseWriter.write(.end, promise: nil)
                    case let .failure(error):
                        responseWriter.write(.error(error), promise: nil)
                    }
                }
        }
    }

    private func handleValue(_ value: Result<Response<EnrichedContent>, Error>, responseWriter: BodyStreamWriter, serviceStreaming: Bool) {
        switch value {
        case let .success(response):
            // If service-streaming is enabled,
            // we response immediately.
            // If service-streaming is not enabled,
            // we only respond once after the .end frame was received.
            if serviceStreaming {
                self.write(response, to: responseWriter)
            }
        case let .failure(error):
            responseWriter.write(.error(error), promise: nil)
        }
    }

    func createStreamingHandler(context: ConnectionContext<GRPCInterfaceExporter>, serviceStreaming: Bool = false)
    -> (Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        { (request: Vapor.Request) in
            if !self.contentTypeIsSupported(request: request) {
                return request.eventLoop.makeFailedFuture(GRPCError.unsupportedContentType(
                    "Content type is currently not supported by Apodini GRPC exporter. Use Protobuffers instead."
                ))
            }

            var context = context
            var lastMessage = GRPCMessage.defaultMessage
            let queue = DispatchQueue(label: "sync-queue")

            let processEvaluation: (Evaluation, BodyStreamWriter) -> Void = { evaluation, writer in
                switch evaluation {
                case let .input(message):
                    lastMessage = message
                    context
                        .handle(request: message, eventLoop: request.eventLoop, final: false)
                        .whenComplete { self.handleValue($0, responseWriter: writer, serviceStreaming: serviceStreaming) }
                case let .observation(observedObject):
                    context
                        .handle(eventLoop: request.eventLoop, observedObject: observedObject)
                        .whenComplete { self.handleValue($0, responseWriter: writer, serviceStreaming: serviceStreaming) }
                case .end:
                    self.handleCompletion(request: request,
                                          context: &context,
                                          responseWriter: writer,
                                          serviceStreaming: serviceStreaming,
                                          lastMessage: lastMessage)
                }
            }

            let streamingResponse: (BodyStreamWriter) -> Void = { writer in
                self.drainClientStream(from: request) { evaluation in
                    queue.sync {
                        processEvaluation(evaluation, writer)
                    }
                }
                context.register(listener: GRPCObservedListener(eventLoop: request.eventLoop) { observedObject in
                    queue.sync {
                        processEvaluation(.observation(observedObject), writer)
                    }
                })
            }

            let response = self.makeResponse(streamingResponse)
            return request.eventLoop.makeSucceededFuture(response)
        }
    }

    /// Exposes a new gRPC method (i.e. a new endpoint) for this service.
    /// The endpoint will be accessible at [host]/[serviceName]/[endpoint].
    /// - Parameters:
    ///     - endpoint: The name of the endpoint that should be exposed.
    ///     - serviceStreaming: Whether this endpoint will respond using a stream.
    func exposeEndpoint(name endpoint: String,
                        context: ConnectionContext<GRPCInterfaceExporter>,
                        serviceStreaming: Bool = false) throws {
        if methodNames.contains(endpoint) {
            throw GRPCServiceError.endpointAlreadyExists
        }
        methodNames.append(endpoint)

        let path = [
            Vapor.PathComponent(stringLiteral: serviceName),
            Vapor.PathComponent(stringLiteral: endpoint)
        ]

        app.on(.POST, path, body: .stream) { request -> EventLoopFuture<Vapor.Response> in
            self.createStreamingHandler(context: context, serviceStreaming: serviceStreaming)(request)
        }
    }
}

extension Array {
    mutating func prepend(_ newElement: Self.Element?, at index: Int) {
        if let element = newElement {
            self.insert(element, at: index)
        }
    }
}
