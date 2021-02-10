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
                                   into input: PassthroughSubject<Evaluation, Never>) {
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
                    input.send(.input(message))
                }
            case .end:
                // This was the last frame on this client-stream.
                input.send(completion: .finished)
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
            if response.isFinal() {
                // If it's a .final response, we send the element and an .end frame.
                self.write(response, to: responseWriter)
                responseWriter.write(.end, promise: nil)
            } else if serviceStreaming {
                // If service-streaming is enabled,
                // we respond immediately.
                // If service-streaming is not enabled,
                // we only respond once after the .end frame was received.
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

            let streamingResponse: (BodyStreamWriter) -> Void = { writer in
                // store the writer to safe it from garbage collection
                let refId = UUID()
                self.writers[refId] = writer

                let input = PassthroughSubject<Evaluation, Never>()

                let cancellable = input
                    .buffer()
                    .syncMap { evaluation -> EventLoopFuture<Response<EnrichedContent>> in
                        switch evaluation {
                        case let .input(message):
                            lastMessage = message
                            return context.handle(request: message, eventLoop: request.eventLoop, final: false)
                        case let .observation(observedObject):
                            return context.handle(eventLoop: request.eventLoop, observedObject: observedObject)
                        }
                    }
                    .sink(
                        receiveCompletion: { _ in
                            self.handleCompletion(request: request,
                                                  context: &context,
                                                  responseWriter: writer,
                                                  serviceStreaming: serviceStreaming,
                                                  lastMessage: lastMessage)
                            // we can get rid of the reference to the writer that we stored,
                            // since the writer will not be needed any more.
                            self.writers.removeValue(forKey: refId)
                            self.cancellables.removeValue(forKey: refId)
                        },
                        receiveValue: { result in
                            self.handleValue(result, responseWriter: writer, serviceStreaming: serviceStreaming)
                        }
                    )
                self.cancellables[refId] = cancellable

                self.drainClientStream(from: request, into: input)
                context.register(listener: GRPCObservedListener(eventLoop: request.eventLoop) { observedObject in
                    input.send(.observation(observedObject))
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

        vaporApp.on(.POST, path, body: .stream) { request -> EventLoopFuture<Vapor.Response> in
            self.createStreamingHandler(context: context, serviceStreaming: serviceStreaming)(request)
        }
    }
}

extension Apodini.Response {
    func isFinal() -> Bool {
        switch self {
        case .final:
            return true
        default:
            return false
        }
    }
}
