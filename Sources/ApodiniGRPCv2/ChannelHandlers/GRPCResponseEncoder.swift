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
                .flatMap {
                    connectionCtx?.handleStreamClose()
                    return context.close()
                }
                .cascade(to: promise)
            return
        case let .message(message, connectionCtx): // TODO rename message here to response or smth like that?
            if !didWriteHeadersFrame {
                var headers = message.headers
                headers[.statusPseudoHeader] = .ok
                headers.applyHTTP2Validations()
                let headersFrame = HTTP2Frame.FramePayload.headers(HTTP2Frame.FramePayload.Headers(
                    headers: headers,
                    priorityData: nil, //<#T##HTTP2Frame.StreamPriorityData?#>,
                    endStream: false,
                    paddingBytes: nil // TODO?
                ))
                print("Writing HEADERS frame", headersFrame, connectionCtx.tmp_method)
                context.writeAndFlush(wrapOutboundOut(headersFrame), promise: nil)
                didWriteHeadersFrame = true
            }
            switch message {
            case let .singleMessage(_, payload, closeStream):
                // TODO this one will resolve the promise directly after writing one message, regardless of whether the stream is kept open or not, whereas the one in the other branch below will only resolve the promise once the stream is closed.! FIX!!!!!
                writeLengthPrefixedMessage(payload, closeStream: closeStream, connectionContext: connectionCtx, channelHandlerContext: context, promise: promise)
                break
            case .stream(_, let stream):
                stream.setObserver { (payload: ByteBuffer, closeStream: Bool) in // TODO does this introduce a retain cycle?
                    print("GRPC STREAM EVENT", payload.readableBytes, closeStream)
                    context.eventLoop.execute {
                        self.writeLengthPrefixedMessage(payload, closeStream: closeStream, connectionContext: connectionCtx, channelHandlerContext: context, promise: promise)
                    }
                }
            }
            do {
//                let messageLength = message.payload.writerIndex
//                precondition(messageLength <= numericCast(UInt32.max))
//                var buffer = ByteBufferAllocator().buffer(capacity: message.payload.writerIndex + 5)
//                buffer.writeInteger(UInt8(0)) // indicate that we have no compression. TODO add compression?
//                buffer.writeInteger(UInt32(messageLength), endianness: .big, as: UInt32.self)
//                buffer.writeImmutableBuffer(message.payload)
//                let dataFrame = HTTP2Frame.FramePayload.data(.init(
//                    data: .byteBuffer(buffer),
//                    endStream: false,
//                    paddingBytes: nil
//                ))
//                print("Writing DATA frame", dataFrame)
//                //context.write(self.wrapOutboundOut(dataFrame), promise: message.shouldCloseStream ? nil : promise)
//                context.writeAndFlush(wrapOutboundOut(dataFrame)).whenComplete { _ in
//                    print("Writing DATA Frame done (prom: \(promise))")
//                    if !message.shouldCloseStream {
//                        promise?.succeed(())
//                    }
//                }
            }
        case .closeStream(let trailers, let msg):
//            let trailers = HTTP2Frame.FramePayload.headers(.init(
//                headers: HPACKHeaders {
//                    GRPCv2Status(code: .ok, message: nil).encode(into: &$0)
//                }.applyingHTTP2Validations(),
//                priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
//                endStream: true,
//                paddingBytes: nil
//            ))
//            print("trailers: \(trailers)")
//            print("Writing TRAILERS frame")
//            context.writeAndFlush(wrapOutboundOut(trailers)).whenComplete { result in
//                print("WROTE TRAILERS", result)
//                context.close(mode: .all).whenComplete { result in
//                    print("CHANNEL CLOSE", result)
//                    promise?.succeed(())
//                }
//            }
            writeTrailers(context: context, msg: msg).cascade(to: promise)
//            if message.shouldCloseStream {
//                let trailers = HTTP2Frame.FramePayload.headers(.init(
//                    headers: HPACKHeaders {
//                        GRPCv2Status(code: .ok, message: nil).encode(into: &$0)
//                    }.applyingHTTP2Validations(),
//                    priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
//                    endStream: true,
//                    paddingBytes: nil
//                ))
//                print("trailers: \(trailers)")
//                print("Writing TRAILERS frame")
//                connectionCtx.handleStreamClose()
//                context.writeAndFlush(self.wrapOutboundOut(trailers), promise: promise)
//            }
        }
        
//        if !didWriteHeaderFrame {
//            didWriteHeaderFrame = true
//            var headers = messageOut.headers
//            headers[.statusPseudoHeader] = .ok
//            headers.validateForHTTP2()
//            let headerFrame = HTTP2Frame.FramePayload.headers(.init(
//                headers: headers,
//                priorityData: nil,
//                endStream: false,
//                paddingBytes: nil
//            ))
//            print("Writing HEADER frame", Thread.current.name, headerFrame)
//            context.write(wrapOutboundOut(headerFrame), promise: nil)
//        }
//
//        do {
//            let messageLength = messageOut.payload.writerIndex
//            precondition(messageLength <= numericCast(UInt32.max))
//            var buffer = ByteBufferAllocator().buffer(capacity: messageOut.payload.writerIndex + 5)
//            buffer.writeInteger(UInt8(0)) // indicate that we have no compression. TODO add compression?
//            buffer.writeInteger(UInt32(messageLength), endianness: .big, as: UInt32.self)
//            buffer.writeImmutableBuffer(messageOut.payload)
//            let dataFrame = HTTP2Frame.FramePayload.data(.init(
//                data: .byteBuffer(buffer),
//                endStream: false,
//                paddingBytes: nil
//            ))
//            print("Writing DATA frame", Thread.current.name, dataFrame)
//            context.write(self.wrapOutboundOut(dataFrame), promise: nil)
//        }
//
//        let trailers = HTTP2Frame.FramePayload.headers(.init(
//            headers: HPACKHeaders {
//                //$0[.statusPseudoHeader] = .ok
//                //$0[.contentType] = .gRPC(.proto)
//                $0[.grpcStatus] = 0
//                $0.add(name: "grpc-message", value: "thisisthemessage")
//            }.validatedForHTTP2(),
//            priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
//            endStream: messageOut.shouldCloseStream,
//            paddingBytes: nil
//        ))
//        print("trailers: \(trailers)")
//        print("Writing TRAILERS frame")
//        context.writeAndFlush(self.wrapOutboundOut(trailers), promise: promise)
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
        print("Writing DATA frame for \(connectionContext.tmp_method)", dataFrame)
        //context.write(self.wrapOutboundOut(dataFrame), promise: message.shouldCloseStream ? nil : promise)
        channelHandlerContext.writeAndFlush(wrapOutboundOut(dataFrame)).whenComplete { _ in
            print("Writing DATA Frame done (prom: \(promise))")
            if !closeStream {
                promise?.succeed(())
            }
        }
        
        if closeStream {
            writeTrailers(context: channelHandlerContext, msg: connectionContext.tmp_method).cascade(to: promise)
//            let trailers = HTTP2Frame.FramePayload.headers(.init(
//                headers: HPACKHeaders {
//                    GRPCv2Status(code: .ok, message: nil).encode(into: &$0)
//                }.applyingHTTP2Validations(),
//                priorityData: nil, // <#T##HTTP2Frame.StreamPriorityData?#>
//                endStream: true,
//                paddingBytes: nil
//            ))
//            print("trailers: \(trailers)")
//            print("Writing TRAILERS frame")
//            connectionContext.handleStreamClose()
//            //channelHandlerContext.writeAndFlush(self.wrapOutboundOut(trailers), promise: promise)
//            channelHandlerContext.write(self.wrapOutboundOut(trailers)).whenComplete { _ in
////                //channelHandlerContext.close(mode: .all, promise: promise)
////                channelHandlerContext.close(mode: .all).whenComplete { result in
////                    print(result)
////                    fatalError()
////                }
//                print("Wrote stream-closing Trailers frame")
//                channelHandlerContext.close(mode: .all).cascade(to: promise)
//            }
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
        print("trailers: \(trailers)")
        print("Writing TRAILERS frame for \(msg)")
        //channelHandlerContext.writeAndFlush(self.wrapOutboundOut(trailers), promise: promise)
        return context.writeAndFlush(self.wrapOutboundOut(trailers))
//            .flatMap {
//                context.close(mode: .all)
//                    .flatMapAlways { result in
//                        print(result)
//                        fatalError()
//                    }
//            }
    }
    
    
    func close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
        print("CLOSE")
        context.close(mode: mode, promise: promise)
    }
    
    func triggerUserOutboundEvent(context: ChannelHandlerContext, event: Any, promise: EventLoopPromise<Void>?) {
        print(Self.self, #function, context, event)
        context.triggerUserOutboundEvent(event, promise: promise)
    }
}

