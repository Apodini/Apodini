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
import NIOHPACK
import NIOTLS
import NIOSSL
import Foundation
import NIOExtras
import NIOFoundationCompat

public final class HTTPClientStreamingHandler<D: StreamingDelegate>: ChannelInboundHandler {
    public typealias InboundIn = HTTP2Frame.FramePayload
    public typealias OutboundOut = HTTP2Frame.FramePayload

    private var streamingDelegate: D
    private weak var context: ChannelHandlerContext?
    private var headersSent = false
    private var buffer = ByteBuffer()

    init(streamingDelegate: D) {
        self.streamingDelegate = streamingDelegate
    }
    
    func sendOutbound(request: D.SRequest) {
        precondition(headersSent)
        do {
            let encoder = JSONEncoder()
            var objectBuffer = try encoder.encodeAsByteBuffer(request, allocator: .init())
            var buffer = ByteBuffer()
            buffer.writeInteger(Int32(objectBuffer.readableBytes))
            buffer.writeBuffer(&objectBuffer)
            
            self.send(buffer)
        } catch {
            print(error)
        }
    }
    
    func send(_ buffer: ByteBuffer) {
        let payload = HTTP2Frame.FramePayload.Data(data: IOData.byteBuffer(buffer), endStream: false)
        let wrapped = self.wrapOutboundOut(.data(payload))
        
        context?.eventLoop.execute { [weak self] in
            self?.context?.writeAndFlush(wrapped, promise: nil)
        }
    }
    
    func close() {
        let emptyBuffer = ByteBuffer()
        
        let payload = HTTP2Frame.FramePayload.Data(data: IOData.byteBuffer(emptyBuffer), endStream: true)
        let wrapped = self.wrapOutboundOut(.data(payload))
        
        context?.eventLoop.execute { [unowned self] in
            self.context?.writeAndFlush(wrapped, promise: nil)
        }
    }

    public func channelActive(context: ChannelHandlerContext) {
        precondition(context.channel.parent!.isActive)
        
        // Send header frame
        var headers = [(String, String)]()
        let simpleHeaders = streamingDelegate.headerFields
        headers.append((":method", simpleHeaders.method.rawValue))
        headers.append((":path", simpleHeaders.url))
        headers.append((":scheme", "https"))
        headers.append((":authority", simpleHeaders.host))
        
        let headerContent = HTTP2Frame.FramePayload.Headers(headers: HPACKHeaders(headers), endStream: false)
        context.writeAndFlush(self.wrapOutboundOut(.headers(headerContent)), promise: nil)

        headersSent = true
        self.context = context
        self.streamingDelegate.handleStreamStart()
        
        context.fireChannelActive()
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let payload = self.unwrapInboundIn(data)
        
        guard case .data(let data) = payload else {
            print("Caught some other frame type than DATA")
            return
        }
        
        guard case .byteBuffer(let newBuffer) = data.data else {
            print("Can't decode from FileRegion")
            return
        }
        
        // Append new buffer to our buffer
        buffer.writeImmutableBuffer(newBuffer)
        
        // Check whether we have a whole object available
        // We get the integer and check whether the stream is long enough.
        guard let int32ByteBuffer = buffer.getSlice(at: 0, length: 4),
              let objectLengthInt32 = int32ByteBuffer.getInteger(at: 0, as: Int32.self),
              buffer.readableBytes >= objectLengthInt32 + 4 else {
            return
        }
        
        let objectLength = Int(objectLengthInt32)
        
        guard let int32AndObjectByteBuffer = buffer.readSlice(length: objectLength + 4) else {
            print("Something is pretty wrong. The stream said it's long enough, but we can't read as much as we're supposed to.")
            return
        }
        
        guard let response = try? int32AndObjectByteBuffer.getJSONDecodable(D.SResponse.self, at: 4, length: objectLength) else {
            print("Something is pretty wrong. We can't read as much data as we would like to.")
            return
        }
        
        buffer.discardReadBytes()
        
        self.streamingDelegate.handleInbound(response: response, serverSideClosed: data.endStream)
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        context.fireErrorCaught(error)
        context.close(promise: nil)
    }
}
