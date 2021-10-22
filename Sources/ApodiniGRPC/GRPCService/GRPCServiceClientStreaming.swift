//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniExtension
import ApodiniLoggingSupport
import ApodiniNetworking


// MARK: Client streaming request handler
extension GRPCService {
    private func drainBody<H: Handler>(
        from request: HTTPRequest,
        factory: DelegateFactory<H, GRPCInterfaceExporter>,
        strategy: AnyDecodingStrategy<GRPCMessage>,
        defaults: DefaultValueStore,
        promise: EventLoopPromise<HTTPResponse>
    ) {
        let delegate = factory.instance()
        
        var lastMessage: GRPCMessage?
        
        request.bodyStorage.drain { chunk in // swiftlint:disable:this closure_body_length
            switch chunk {
            case .buffer(let buffer):
                guard let data = buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes) else {
                    promise.fail(GRPCError.payloadReadError("Cannot read byte-buffer from fragment"))
                    return
                }

                // retrieve all GRPC messages that were delivered in this request
                // (may be none, one or multiple)
                var messages = self.getMessages(from: data, remoteAddress: request.remoteAddress)
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
                        let basis = DefaultRequestBasis(
                            base: message,
                            remoteAddress: message.remoteAddress,
                            information: request.information.merge(with: Self.getLoggingMetadataInformation(message))
                        )
                        
                        let response: EventLoopFuture<Apodini.Response<H.Response.Content>> = strategy
                            .decodeRequest(from: message, with: basis, with: request.eventLoop)
                            .insertDefaults(with: defaults)
                            .cache()
                            .evaluate(on: delegate, .open)
                        
                        // Discard any result that is received back from the handler.
                        // This is a client-streaming handler, thus we only send back
                        // a response in the .end case.
                        _ = response
                    })
            case .end:
                // send the previously retained lastMessage through the handler
                // and set the final flag
                let message = lastMessage ?? GRPCMessage.defaultMessage
                
                let basis = DefaultRequestBasis(
                    base: message,
                    remoteAddress: message.remoteAddress,
                    information: request.information.merge(with: Self.getLoggingMetadataInformation(message))
                )
                
                let response: EventLoopFuture<Apodini.Response<H.Response.Content>> = strategy
                    .decodeRequest(from: message, with: basis, with: request.eventLoop)
                    .insertDefaults(with: defaults)
                    .cache()
                    .evaluate(on: delegate, .end)
                
                let result = response.map { response -> HTTPResponse in
                    switch response.content {
                    case let .some(content):
                        return self.makeResponse(content)
                    case .none:
                        return self.makeResponse()
                    }
                }

                promise.completeWith(result)
            }
        }
    }

    func createClientStreamingHandler<H: Handler>(
        factory: DelegateFactory<H, GRPCInterfaceExporter>,
        strategy: AnyDecodingStrategy<GRPCMessage>,
        defaults: DefaultValueStore
    ) -> (HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        { (request: HTTPRequest) in
            if !self.contentTypeIsSupported(request: request) {
                return request.eventLoop.makeFailedFuture(GRPCError.unsupportedContentType(
                    "Content type is currently not supported by Apodini GRPC exporter. Use Protobuffers instead."
                ))
            }

            let promise = request.eventLoop.makePromise(of: HTTPResponse.self)
            self.drainBody(from: request, factory: factory, strategy: strategy, defaults: defaults, promise: promise)
            return promise.futureResult
        }
    }

    /// Exposes a client streaming endpoint for the handle that the service was initialized with.
    /// The endpoint will be accessible at [host]/[serviceName]/[endpoint].
    /// - Parameters:
    ///     - endpoint: The name of the endpoint that should be exposed.
    func exposeClientStreamingEndpoint<H: Handler>(
        name methodName: String? = nil,
        _ endpoint: Endpoint<H>,
        strategy: AnyDecodingStrategy<GRPCMessage>
    ) throws {
        let methodName = methodName ?? gRPCMethodName(from: endpoint)
        
        if methodNames.contains(methodName) {
            throw GRPCServiceError.endpointAlreadyExists
        }
        methodNames.append(methodName)
        
        app.httpServer.registerRoute(.POST, [.verbatim(serviceName), .verbatim(methodName)]) { request in
            self.createClientStreamingHandler(
                factory: endpoint[DelegateFactory<H, GRPCInterfaceExporter>.self],
                strategy: strategy,
                defaults: endpoint[DefaultValueStore.self]
            )(request)
        }
    }
    
    static func getLoggingMetadataInformation(_ message: GRPCMessage) -> [LoggingMetadataInformation] {
         [
            LoggingMetadataInformation(key: .init("data"), rawValue: message.data.count <= 32_768 ? .string(message.data.base64EncodedString()) : .string("\(message.data.base64EncodedString().prefix(32_715))... (Further bytes omitted since data too large!)")),
            LoggingMetadataInformation(key: .init("dataLength"), rawValue: .string(message.length.description)),
            LoggingMetadataInformation(key: .init("compression"), rawValue: .string(message.compressed.description)),
            LoggingMetadataInformation(key: .init("didCollectAllFragments"), rawValue: .string(message.didCollectAllFragments.description))
         ]
     }
}
