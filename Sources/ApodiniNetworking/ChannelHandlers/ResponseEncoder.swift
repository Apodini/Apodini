//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO
import NIOHTTP1


class HTTPServerResponseEncoder: ChannelOutboundHandler, RemovableChannelHandler {
    private enum State {
        case ready
        case waitingOnStream
    }
    
    typealias OutboundIn = HTTPResponse
    typealias OutboundOut = HTTPServerResponsePart
    
    private var state: State = .ready
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let response = unwrapOutboundIn(data)
        switch state {
        case .ready:
            // We were waiting for incoming responses, and have now received one.
            let responseHead = HTTPResponseHead(
                version: response.version,
                status: response.status,
                headers: response.headers
            )
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            switch response.bodyStorage {
            case .buffer(let buffer):
                if buffer.readableBytes > 0 {
                    context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
                }
                context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: promise)
                return
            case .stream(let stream):
                state = .waitingOnStream
                handleStreamWrite(context: context, stream: stream, promise: promise)
            }
        case .waitingOnStream:
            handleStreamWrite(context: context, stream: response.bodyStorage.stream!, promise: promise)
        }
    }
    
    
    private func handleStreamWrite(context: ChannelHandlerContext, stream: BodyStorage.Stream, promise: EventLoopPromise<Void>?) {
        precondition(state == .waitingOnStream)
        // We've already handled part of this request, and now have to write the newly available data
        if stream.readableBytes > 0 {
            context.writeAndFlush(wrapOutboundOut(.body(.byteBuffer(stream.readNewData()!))), promise: nil)
        }
        if stream.isClosed {
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: promise)
            state = .ready
        }
    }
    
    
    func handlerRemoved(context: ChannelHandlerContext) {
        precondition(state != .waitingOnStream, "Handler was removed from pipeline while waiting on a stream")
    }
}
