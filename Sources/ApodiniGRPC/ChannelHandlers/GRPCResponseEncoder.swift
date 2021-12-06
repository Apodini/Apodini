//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIO
import NIOHTTP2
import NIOHPACK
import Logging


class GRPCResponseEncoder: ChannelOutboundHandler {
    typealias OutboundIn = GRPCMessageHandler.Output
    typealias OutboundOut = HTTP2Frame.FramePayload
    
    
    private let logger: Logger
    private var didWriteHeadersFrame = false
    
    init() {
        self.logger = Logger(label: "[\(Self.self)]")
    }
    
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let response = unwrapOutboundIn(data)
        
        switch response {
        case let .error(status, connectionCtx):
            let trailersFrame = HTTP2Frame.FramePayload.headers(HTTP2Frame.FramePayload.Headers(
                headers: HPACKHeaders {
                    if !didWriteHeadersFrame {
                        $0[.statusPseudoHeader] = .ok
                        $0[.contentType] = .gRPC(.proto)
                    }
                    status.encode(into: &$0)
                }.applyingHTTP2Validations(),
                priorityData: nil,
                endStream: true,
                paddingBytes: nil
            ))
            context.write(wrapOutboundOut(trailersFrame))
                .flatMap {
                    if let handleCloseFuture = connectionCtx?.handleStreamClose() {
                        // Note that in this case (the connection being shut down due to some server-side error), we do of course
                        // still invoke the connection context's handleClose function, but ignore the value the future returned by
                        // that function might evaluate to. The reason, of course, being that at this point in time we've already
                        // written the TRAILERS frame, so there's no point in writing any further data to the connection.
                        return handleCloseFuture.flatMapAlways { _ in context.close() }
                    } else {
                        return context.close()
                    }
                }
                .cascade(to: promise)
            return
        case let .message(message, connectionCtx):
            let writeHeadersFuture: EventLoopFuture<Void>
            if !didWriteHeadersFrame {
                didWriteHeadersFrame = true
                var headers = message.headers
                precondition(headers.isPresent(.contentType) && headers[.contentType]!.encodeToHTTPHeaderFieldValue().hasPrefix("application/grpc"))
                headers[.statusPseudoHeader] = .ok
                headers.applyHTTP2Validations()
                let headersFrame = HTTP2Frame.FramePayload.headers(HTTP2Frame.FramePayload.Headers(
                    headers: headers,
                    priorityData: nil,
                    endStream: false,
                    paddingBytes: nil
                ))
                writeHeadersFuture = context.writeAndFlush(wrapOutboundOut(headersFrame))
            } else {
                writeHeadersFuture = context.eventLoop.makeSucceededVoidFuture()
            }
            switch message {
            case .nothing:
                writeHeadersFuture.cascade(to: promise)
            case let .singleMessage(_, payload, closeStream):
                writeHeadersFuture.flatMap { _ in
                    self.writeLengthPrefixedMessage(
                        payload,
                        closeStream: closeStream,
                        connectionContext: connectionCtx,
                        channelHandlerContext: context
                    )
                }
                .cascade(to: promise)
            case .stream(_, let stream):
                stream.setObserver { (payload: ByteBuffer, closeStream: Bool) in
                    // Write, on the context event loop, the message to the channel.
                    // If this is the last message in the stream, fulfill the promise we got with the write.
                    // NOTE: This will effectively block the handler from receiving further messages while the response stream is still active.
                    // Also, this behaviour only makes sense for service-side-streaming endpoints, where a single client message is
                    // responded to with one or more server responses. The main issue with this behaviour is that closing the response stream
                    // (which was opened in response to a single message) will also close the underlying HTTP connection.
                    // This is fine for service-side-streaming endpoints, but not for bidirectional endpoints, since in this case
                    // the end end of a single response stream does not imply the end of the RPC connection as a whole.
                    context.eventLoop.execute {
                        let writeFuture = self.writeLengthPrefixedMessage(
                            payload,
                            closeStream: closeStream,
                            connectionContext: connectionCtx,
                            channelHandlerContext: context
                        )
                        if closeStream {
                            writeFuture.cascade(to: promise)
                        }
                    }
                }
            }
            
        case .closeStream(trailers: _):
            writeTrailers(context: context).cascade(to: promise)
        }
    }
    
    
    private func writeLengthPrefixedMessage(
        _ payload: ByteBuffer,
        closeStream: Bool,
        connectionContext: GRPCStreamConnectionContext,
        channelHandlerContext: ChannelHandlerContext
    ) -> EventLoopFuture<Void> {
        let messageLength = payload.writerIndex
        precondition(messageLength <= numericCast(UInt32.max))
        var buffer = ByteBufferAllocator().buffer(capacity: payload.writerIndex + 5)
        buffer.writeInteger(UInt8(0)) // indicate that we have no compression.
        buffer.writeInteger(UInt32(messageLength), endianness: .big, as: UInt32.self)
        buffer.writeImmutableBuffer(payload)
        let dataFrame = HTTP2Frame.FramePayload.data(.init(
            data: .byteBuffer(buffer),
            endStream: false,
            paddingBytes: nil
        ))
        let future = channelHandlerContext.writeAndFlush(wrapOutboundOut(dataFrame))
        if closeStream {
            return future.flatMap { _ in
                self.writeTrailers(context: channelHandlerContext)
            }
        } else {
            return future
        }
    }
    
    
    private func writeTrailers(context: ChannelHandlerContext) -> EventLoopFuture<Void> {
        let trailers = HTTP2Frame.FramePayload.headers(.init(
            headers: HPACKHeaders {
                GRPCStatus(code: .ok, message: nil).encode(into: &$0)
            }.applyingHTTP2Validations(),
            priorityData: nil,
            endStream: true,
            paddingBytes: nil
        ))
        return context.writeAndFlush(self.wrapOutboundOut(trailers))
    }
    
    
    func close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
        context.close(mode: mode, promise: promise)
    }
    
    func triggerUserOutboundEvent(context: ChannelHandlerContext, event: Any, promise: EventLoopPromise<Void>?) {
        context.triggerUserOutboundEvent(event, promise: promise)
    }
}
