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
import ApodiniUtils
import Foundation


class UnaryRPCHandler<H: Handler>: StreamRPCHandlerBase<H> {
    override func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut> {
        let responseFuture: EventLoopFuture<Apodini.Response<H.Response.Content>> = decodingStrategy
            .decodeRequest(from: message, with: message, with: context.eventLoop)
            .insertDefaults(with: defaults)
            .cache()
            .forwardDecodingErrors(with: errorForwarder)
            .evaluate(on: delegate)
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
                self?.errorForwarder.forwardError(error)
            }
    }
}
