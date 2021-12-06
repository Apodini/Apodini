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


// NOTE that this needs a rework (as does the HTTP IE's bidirectional stream handling), to add proper support for streams other than client req -> server res.
// The problem is that e.g. it currently isn't really possible to respond to one client request w/ multiple separate responses.
// Why? 1. There is no way for the handler to return twice, you'd have to use like the ObservedObject stuff to get that working.
// But even then there's really no good way for the handler to differentiate between getting called for a proper message or for one of these observed object calls.
// Also, the NIO channel handler calling the handler will somehow need to know about the fact that the handler is currently still busy, so that it can wait with handling new incoming requests until the handler is done handling the current one.
class BidirectionalStreamRPCHandler<H: Handler>: StreamRPCHandlerBase<H> {
    override func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut> {
        let headers = HPACKHeaders {
            $0[.contentType] = .gRPC(.proto)
        }
        let abortAnyError = AbortTransformer()
        let retFuture: EventLoopFuture<GRPCMessageOut> = [message]
            .asAsyncSequence
            .decode(using: decodingStrategy, with: context.eventLoop)
            .insertDefaults(with: defaults)
            .cache()
            .subscribe(to: delegate)
            .evaluate(on: delegate)
            .transform(using: abortAnyError)
            .cancelIf { $0.connectionEffect == .close }
            .firstFuture(on: context.eventLoop)
            .map { (response: Response<H.Response.Content>?) -> GRPCMessageOut in
                guard let response = response else {
                    fatalError("Unexpectedly got a nil response from the handler")
                }
                if response.isNothing {
                    return .nothing(headers)
                } else if let content = response.content {
                    return .singleMessage(
                        headers: headers,
                        payload: try! self.encodeResponseIntoProtoMessage(content),
                        closeStream: response.connectionEffect == .close
                    )
                } else {
                    // We got a response which is not .nothing, but also doesn't contain any content. Do we still want to send a message back to the client?
                    return .singleMessage(headers: headers, payload: ByteBuffer(), closeStream: response.connectionEffect == .close)
                }
            }
        return retFuture
    }
}
