//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//  

import NIO
import NIOHTTP1
import NIOHTTP2
import NIOTLS
import NIOSSL
import Foundation
import NIOExtras

/// Fires off the requests (which were passed in in `init`) when our stream is active and collects all response parts into a promise.
///
/// - warning: This will read the whole response into memory and delivers it into a promise.
final class SendRequestsHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPClientResponsePart
    typealias OutboundOut = HTTPClientRequestPart

    private let responseReceivedPromise: EventLoopPromise<[[HTTPClientResponsePart]]>
    private var responsePartAccumulator: [[HTTPClientResponsePart]] = []
    private var currentResponse: [HTTPClientResponsePart] = []
    private let host: String
    private let requests: [TestHTTPRequest]

    init(host: String, requests: [TestHTTPRequest], responseReceivedPromise: EventLoopPromise<[[HTTPClientResponsePart]]>) {
        self.responseReceivedPromise = responseReceivedPromise
        self.host = host
        self.requests = requests
    }

    func channelActive(context: ChannelHandlerContext) {
        assert(context.channel.parent!.isActive)
        // Send all the requests
        for request in self.requests {
            var headers = HTTPHeaders(request.headers)
            headers.add(name: "host", value: self.host)
            var reqHead = HTTPRequestHead(version: request.version,
                                          method: request.method,
                                          uri: request.target)
            reqHead.headers = headers
            context.write(self.wrapOutboundOut(.head(reqHead)), promise: nil)
            if let body = request.body {
                var buffer = context.channel.allocator.buffer(capacity: body.count)
                buffer.writeBytes(body)
                context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            }
        }
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        context.fireChannelActive()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        self.responseReceivedPromise.fail(error)
        context.fireErrorCaught(error)
        context.close(promise: nil)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let resPart = self.unwrapInboundIn(data)
        switch(resPart) {
        case .body, .head:
            currentResponse.append(resPart)
        case .end:
            self.responsePartAccumulator.append(currentResponse)
            currentResponse = []
        }
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        self.responseReceivedPromise.succeed(responsePartAccumulator)
        context.fireChannelInactive()
    }
}
