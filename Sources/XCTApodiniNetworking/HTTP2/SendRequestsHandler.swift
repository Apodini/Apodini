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
    typealias InboundIn = HTTP2Frame.FramePayload
    typealias OutboundOut = HTTP2Frame.FramePayload

    private let responseReceivedPromise: EventLoopPromise<[[HTTP2Frame.FramePayload]]>
    private var responsePartAccumulator: [[HTTP2Frame.FramePayload]] = []
    private var currentResponse: [HTTP2Frame.FramePayload] = []
    private let host: String
    private let requests: [TestHTTPRequest]

    init(host: String, requests: [TestHTTPRequest], responseReceivedPromise: EventLoopPromise<[[HTTP2Frame.FramePayload]]>) {
        self.responseReceivedPromise = responseReceivedPromise
        self.host = host
        self.requests = requests
    }

    func channelActive(context: ChannelHandlerContext) {
        assert(context.channel.parent!.isActive)
        // Send all the requests
        for request in self.requests {
            let noBody = request.body == nil
            
            var headersArray = request.headers
            headersArray.append((":method", "GET")) // TODO use request method
            headersArray.append((":path", request.target))
            headersArray.append((":scheme", "https"))
            headersArray.append((":authority", self.host))
            
            let headerContent = HTTP2Frame.FramePayload.Headers(headers: HPACKHeaders(headersArray), endStream: noBody)
            context.writeAndFlush(self.wrapOutboundOut(.headers(headerContent)), promise: nil)

            if !noBody, let body = request.body {
                var buffer: ByteBuffer
                buffer = context.channel.allocator.buffer(capacity: body.count)
                buffer.writeBytes(body)
                context.writeAndFlush(self.wrapOutboundOut(.data(HTTP2Frame.FramePayload.Data(data: IOData.byteBuffer(buffer), endStream: true))), promise: nil)
            }
        }
//        let emptyBuffer = context.channel.allocator.buffer(capacity: 0)
//        context.writeAndFlush(self.wrapOutboundOut(.data(HTTP2Frame.FramePayload.Data(data: IOData.byteBuffer(emptyBuffer), endStream: true))), promise: nil)
        context.fireChannelActive()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        self.responseReceivedPromise.fail(error)
        context.fireErrorCaught(error)
        context.close(promise: nil)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let payload = self.unwrapInboundIn(data)
        currentResponse.append(payload)
        switch payload {
        case .data(let data):
            if data.endStream {
                self.responsePartAccumulator.append(currentResponse)
            }
        default:
            break
        }
//        switch(resPart) {
//        case .body, .head:
//            currentResponse.append(resPart)
//        case .end:
//            self.responsePartAccumulator.append(currentResponse)
//            currentResponse = []
//        }
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        self.responseReceivedPromise.succeed(responsePartAccumulator)
        context.fireChannelInactive()
    }
}
