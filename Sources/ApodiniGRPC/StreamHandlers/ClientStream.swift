//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniExtension
import NIO
import NIOHPACK
import Foundation


class ClientSideStreamRPCHandler<H: Handler>: StreamRPCHandlerBase<H> {
    private var lastRequest: GRPCMessageIn?
    
    override func handleStreamClose(context: any GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut>? {
        let message = self.lastRequest!
        let responseFuture: EventLoopFuture<Apodini.Response<H.Response.Content>> = self.decodingStrategy
            .decodeRequest(from: message, with: message, with: context.eventLoop)
            .insertDefaults(with: self.defaults)
            .cache()
            .forwardDecodingErrors(with: errorForwarder)
            .evaluate(on: self.delegate, .close)
        return responseFuture
            .map { (response: Apodini.Response<H.Response.Content>) -> GRPCMessageOut in
                let headers = HPACKHeaders {
                    $0[.contentType] = .gRPC(.proto)
                }
                guard let responseContent = response.content else {
                    return .singleMessage(headers: headers, payload: ByteBuffer(), closeStream: true)
                }
                return .singleMessage(
                    headers: headers,
                    payload: try! self.encodeResponseIntoProtoMessage(responseContent),
                    closeStream: true
                )
            }
            .inspectFailure { [weak self] error in
                self?.errorForwarder.forward(error)
            }
    }
    
    override func handle(message: GRPCMessageIn, context: any GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut> {
        self.lastRequest = message
        let abortAnyError = ErrorForwardingResultTransformer(
            wrapped: AbortTransformer(),
            forwarder: errorForwarder
        )
        let headers = HPACKHeaders {
            $0[.contentType] = .gRPC(.proto)
        }
        return [message]
            .asAsyncSequence
            .decode(using: decodingStrategy, with: context.eventLoop)
            .insertDefaults(with: defaults)
            .cache()
            .forwardDecodingErrors(with: errorForwarder)
            .subscribe(to: delegate)
            .evaluate(on: delegate)
            .transform(using: abortAnyError)
            .cancelIf { $0.connectionEffect == .close }
            .firstFuture(on: context.eventLoop)
            .flatMapAlways { (result: Result<Apodini.Response<H.Response.Content>?, Error>) -> EventLoopFuture<GRPCMessageOut> in
                switch result {
                case .failure(let error):
                    fatalError("\(error)")
                case .success(.none):
                    fatalError("Handler response sequence was empty.")
                case .success(.some(let response)):
                    if response.isNothing {
                        // The handler returned a `.nothing` response, indicating to us that the connection should be kept open and a response will be sent with a future client request
                        return context.eventLoop.makeSucceededFuture(.nothing(headers))
                    } else {
                        guard let responseContent = response.content else {
                            // Important question. What semantics do we want for client-streaming RPC handlers?
                            // The way this should end up working is that the client can send as many requests as they want, and the first "non-nothing"
                            // response from the handler will terminate the call.
                            // Question: do we accept only `.nothing` responses as "keep the stream open" responses, or also empty responses.
                            // What if the handler intentionally wants to end the stream w/ an empty response?
                            return context.eventLoop.makeSucceededFuture(.singleMessage(
                                headers: headers,
                                payload: ByteBuffer(),
                                closeStream: true
                            ))
                        }
                        return context.eventLoop.makeSucceededFuture(.singleMessage(
                            headers: headers,
                            payload: try! self.encodeResponseIntoProtoMessage(responseContent),
                            closeStream: true
                        ))
                    }
                }
            }
    }
}
