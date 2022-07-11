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
    private let requestStream: HTTP2RequestStream<AddStruct>

    init(host: String, requests: HTTP2RequestStream<AddStruct>, responseReceivedPromise: EventLoopPromise<[[HTTP2Frame.FramePayload]]>) {
        self.responseReceivedPromise = responseReceivedPromise
        self.host = host
        self.requestStream = requests
    }

    func channelActive(context: ChannelHandlerContext) {
        assert(context.channel.parent!.isActive)
        // Send header frame
        var headers = [(String, String)]()
        headers.append((":method", requestStream.method.rawValue)) // TODO use request method
        headers.append((":path", requestStream.url))
        headers.append((":scheme", "https"))
        headers.append((":authority", self.host))
        
        let headerContent = HTTP2Frame.FramePayload.Headers(headers: HPACKHeaders(headers), endStream: false)
        context.writeAndFlush(self.wrapOutboundOut(.headers(headerContent)), promise: nil)
        
        let encoder = JSONEncoder()
        
        // Send requests as DATA frames
        for (index, request) in self.requestStream.requests.enumerated() {
            do {
                let buffer = try encoder.encodeAsByteBuffer(request, allocator: .init())
                let endStream = index == requestStream.requests.count - 1
                
                    context.writeAndFlush(self.wrapOutboundOut(.data(HTTP2Frame.FramePayload.Data(data: IOData.byteBuffer(buffer), endStream: endStream))), promise: nil)
            } catch {
                print(error)
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
