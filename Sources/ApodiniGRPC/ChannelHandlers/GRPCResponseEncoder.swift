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
            //precondition(!didWriteHeaderFrame, "Invalid state. Received \(response), but a HEADER frame was already written previously")
            let trailersFrame = HTTP2Frame.FramePayload.headers(HTTP2Frame.FramePayload.Headers(
                headers: HPACKHeaders {
                    status.encode(into: &$0)
                }.applyingHTTP2Validations(),
                priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
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
        case let .message(message, connectionCtx): // TODO rename message here to response or smth like that?
            let writeHeadersFuture: EventLoopFuture<Void>
            if !didWriteHeadersFrame {
                didWriteHeadersFrame = true
                var headers = message.headers
                precondition(headers.isPresent(.contentType) && headers[.contentType]!.encodeToHTTPHeaderFieldValue().hasPrefix("application/grpc"))
                headers[.statusPseudoHeader] = .ok
                headers.applyHTTP2Validations()
                let headersFrame = HTTP2Frame.FramePayload.headers(HTTP2Frame.FramePayload.Headers(
                    headers: headers,
                    priorityData: nil, //<#T##HTTP2Frame.StreamPriorityData?#>,
                    endStream: false,
                    paddingBytes: nil // TODO?
                ))
                writeHeadersFuture = context.writeAndFlush(wrapOutboundOut(headersFrame))
//                future.whenComplete { result in
//                    self.logger.notice("AAAAAA Writing HEADERS frame done: \(result)")
//                }
//                future.whenComplete { result in
//                    self.logger.notice("BBBBBB Writing HEADERS frame done: \(result)")
//                }
            } else {
                writeHeadersFuture = context.eventLoop.makeSucceededVoidFuture()
            }
            //promise?.futureResult.map(<#T##callback: (Void) -> (NewValue)##(Void) -> (NewValue)#>)
            switch message {
            case .nothing:
                writeHeadersFuture.cascade(to: promise)
            case let .singleMessage(_, payload, closeStream):
                // TODO this one will resolve the promise directly after writing one message, regardless of whether the stream is kept open or not, whereas the one in the other branch below will only resolve the promise once the stream is closed.! FIX!!!!!
                writeHeadersFuture.flatMap { _ in
                    self.writeLengthPrefixedMessage(
                        payload, closeStream: closeStream,
                        connectionContext: connectionCtx,
                        channelHandlerContext: context
                    )
                }
                .cascade(to: promise)
            case .stream(_, let stream):
                stream.setObserver { (payload: ByteBuffer, closeStream: Bool) in // TODO does this introduce a retain cycle?
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
            
        case .closeStream(let trailers, let msg):
            writeTrailers(context: context, msg: msg)
                .cascade(to: promise)
        }
    }
    
    
    private func writeLengthPrefixedMessage(
        _ payload: ByteBuffer,
        closeStream: Bool,
        connectionContext: GRPCStreamConnectionContext,
        channelHandlerContext: ChannelHandlerContext
    //promise: EventLoopPromise<Void>?
    ) -> EventLoopFuture<Void> {
        let messageLength = payload.writerIndex
        precondition(messageLength <= numericCast(UInt32.max))
        var buffer = ByteBufferAllocator().buffer(capacity: payload.writerIndex + 5)
        buffer.writeInteger(UInt8(0)) // indicate that we have no compression. TODO add compression?
        buffer.writeInteger(UInt32(messageLength), endianness: .big, as: UInt32.self)
        buffer.writeImmutableBuffer(payload)
        let dataFrame = HTTP2Frame.FramePayload.data(.init(
            data: .byteBuffer(buffer),
            endStream: false,
            paddingBytes: nil
        ))
        let future = channelHandlerContext.writeAndFlush(wrapOutboundOut(dataFrame))
//            .whenComplete { result in
//            self.logger.notice("writeLengthPrefixedMessage done[1]: \(result)")
//            if !closeStream {
//                promise?.succeed(())
//            }
//        }
        
        if closeStream {
            return future.flatMap { _ in
                self.writeTrailers(context: channelHandlerContext, msg: connectionContext.grpcMethodName)
            }
        } else {
            return future
        }
        
//        if closeStream {
//            writeTrailers(context: channelHandlerContext, msg: connectionContext.grpcMethodName)
//                .inspect {
//                    self.logger.notice("writeLengthPrefixedMessage done[2]: \($0)")
//                }
//                .cascade(to: promise)
//        }
    }
    
    
    private func writeTrailers(context: ChannelHandlerContext, msg: String) -> EventLoopFuture<Void> {
        let trailers = HTTP2Frame.FramePayload.headers(.init(
            headers: HPACKHeaders {
                GRPCStatus(code: .ok, message: nil).encode(into: &$0)
            }.applyingHTTP2Validations(),
            priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
            endStream: true,
            paddingBytes: nil
        ))
        return context.writeAndFlush(self.wrapOutboundOut(trailers))
            .inspect {
                self.logger.notice("writeTrailers done: \($0) [msg: \(msg)]")
            }
    }
    
    
    func close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
        context.close(mode: mode, promise: promise)
    }
    
    func triggerUserOutboundEvent(context: ChannelHandlerContext, event: Any, promise: EventLoopPromise<Void>?) {
        context.triggerUserOutboundEvent(event, promise: promise)
    }
}

