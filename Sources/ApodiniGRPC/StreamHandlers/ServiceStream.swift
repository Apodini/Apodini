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


class ServiceSideStreamRPCHandler<H: Handler>: StreamRPCHandlerBase<H> {
    override func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut> {
        print(Self.self, #function)
        let responsesStream = GRPCMessageOut.Stream()
        let abortAnyError = ErrorForwardingResultTransformer(
            wrapped: AbortTransformer(),
            forwarder: errorForwarder
        )
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
            .firstFutureAndForEach(
                on: context.eventLoop,
                objectsHandler: { (response: Apodini.Response<H.Response.Content>) -> Void in
                    print(Self.self, #function, "GOT A RESPONSE FROM THE HANDLER")
                    do {
                        if let content = response.content {
                            let buffer = try self.encodeResponseIntoProtoMessage(content)
                            responsesStream.write((buffer, closeStream: response.connectionEffect == .close))
                        } else {
                            responsesStream.write((ByteBuffer(), closeStream: response.connectionEffect == .close))
                        }
                    } catch {
                        fatalError("Error encoding part of response: \(error)")
                    }
                }
            )
            .map { _ -> GRPCMessageOut in
                GRPCMessageOut.stream(
                    HPACKHeaders {
                        $0[.contentType] = .gRPC(.proto)
                    },
                    responsesStream
                )
            }
            .inspectFailure { [weak self] error in
                self?.errorForwarder.forward(error)
            }
    }
}
