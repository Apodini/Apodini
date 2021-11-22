import Foundation
import NIO
import NIOHTTP2
import NIOHPACK


class GRPCv2ResponseEncoder: ChannelOutboundHandler {
    typealias OutboundIn = GRPCv2MessageHandler.Output
    typealias OutboundOut = HTTP2Frame.FramePayload
    
    
    private var didWriteHeadersFrame = false
    
    
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
                .flatMap { // TODO do we really want this here, or should that be moved to whereever we're getting the .error messageOut from (the message handler, presumably), which would then put that into a whenComplete callback somehwere there???!!!!!!
                    connectionCtx?.handleStreamClose()
                    return context.close()
                }
                .cascade(to: promise)
            return
        case let .message(message, connectionCtx): // TODO rename message here to response or smth like that?
            if !didWriteHeadersFrame {
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
                context.writeAndFlush(wrapOutboundOut(headersFrame)).whenComplete { _ in
                    print("Writing HEADERS frame done")
                }
                didWriteHeadersFrame = true
            }
            switch message {
            case .nothing:
                break
            case let .singleMessage(_, payload, closeStream):
                // TODO this one will resolve the promise directly after writing one message, regardless of whether the stream is kept open or not, whereas the one in the other branch below will only resolve the promise once the stream is closed.! FIX!!!!!
                writeLengthPrefixedMessage(payload, closeStream: closeStream, connectionContext: connectionCtx, channelHandlerContext: context, promise: promise)
                break
            case .stream(_, let stream):
                stream.setObserver { (payload: ByteBuffer, closeStream: Bool) in // TODO does this introduce a retain cycle?
                    context.eventLoop.execute {
                        self.writeLengthPrefixedMessage(payload, closeStream: closeStream, connectionContext: connectionCtx, channelHandlerContext: context, promise: promise)
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
        connectionContext: GRPCv2StreamConnectionContext,
        channelHandlerContext: ChannelHandlerContext,
        promise: EventLoopPromise<Void>?
    ) {
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
        channelHandlerContext.writeAndFlush(wrapOutboundOut(dataFrame)).whenComplete { _ in
            if !closeStream {
                promise?.succeed(())
            }
        }
        
        if closeStream {
            writeTrailers(context: channelHandlerContext, msg: connectionContext.grpcMethodName)
                .cascade(to: promise)
        }
    }
    
    
    private func writeTrailers(context: ChannelHandlerContext, msg: String) -> EventLoopFuture<Void> {
        let trailers = HTTP2Frame.FramePayload.headers(.init(
            headers: HPACKHeaders {
                GRPCv2Status(code: .ok, message: nil).encode(into: &$0)
            }.applyingHTTP2Validations(),
            priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
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

