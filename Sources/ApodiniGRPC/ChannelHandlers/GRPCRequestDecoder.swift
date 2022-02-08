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
import ApodiniUtils
import Logging


class GRPCRequestDecoder: ChannelInboundHandler {
    typealias InboundIn = HTTP2Frame.FramePayload
    typealias InboundOut = GRPCMessageHandler.Input
    typealias OutboundOut = HTTP2Frame.FramePayload
    
    /// Context of a message currently being collected from the stream
    private class MessageCollectionContext: Hashable {
        let expectedPayloadSize: Int
        let compression: GRPCMessageCompressionType?
        var buffer = ByteBuffer() {
            didSet { assert(buffer.writerIndex <= expectedPayloadSize) }
        }
        
        init(expectedPayloadSize: Int, compression: GRPCMessageCompressionType?) {
            self.expectedPayloadSize = expectedPayloadSize
            self.compression = compression
        }
        
        var numMissingPayloadBytes: Int {
            expectedPayloadSize - buffer.writerIndex
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self))
        }
        
        static func == (lhs: MessageCollectionContext, rhs: MessageCollectionContext) -> Bool {
            ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        }
    }
    
    private enum State: Equatable {
        case ready
        /// - parameter initialHeaders: The headers received with the initial request that opened the stream.
        /// - parameter messageCollectionCtx: Context object containing infrmation about the (gRPC) message currently being collected from the stream.
        ///         This will only be set to a nonnull value while reading a message which is spread across multiple DATA frames.
        case handlingStream(initialHeaders: HPACKHeaders, messageCollectionCtx: MessageCollectionContext?)
        /// The RPC stream has ended and the channel is now closed.
        case closed
    }
    
    
    private let logger: Logger
    private var state: State = .ready
    
    
    init() {
        self.logger = Logger(label: "[\(Self.self)]")
        logger.notice("\(#function)")
    }
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) { // swiftlint:disable:this cyclomatic_complexity
        let input = unwrapInboundIn(data)
        
        guard self.state != .closed else {
            logger.error("Received unexpected frame on closed channel: \(input)")
            _ = context.close()
            return
        }
        
        switch input {
        case .data(let dataFrame): // data: HTTP2Frame.FramePayload.Data
            defer {
                precondition(dataFrame.endStream == (state == .closed))
            }
            switch dataFrame.data {
            case .byteBuffer(let buffer):
                switch state {
                case .ready:
                    fatalError("Invalid state: .ready when receiving DATA frame.")
                case let .handlingStream(initialHeaders, messageCollectionCtx):
                    var dataFrameDataBuffer = buffer
                    if dataFrameDataBuffer.readableBytes == 0 && dataFrame.endStream {
                        self.state = .closed
                        context.fireChannelRead(self.wrapInboundOut(.closeStream(reason: .client)))
                        return
                    }
                    let didReadForPrevMessage: Bool
                    if let messageCollectionCtx = messageCollectionCtx {
                        if dataFrameDataBuffer.readableBytes >= messageCollectionCtx.numMissingPayloadBytes {
                            // The DATA frame contains more bytes than what we're missing, so we just consume the ones belonging to us, turn that into a message, and move on
                            let remainingBytes = dataFrameDataBuffer.readSlice(length: messageCollectionCtx.numMissingPayloadBytes)!
                            messageCollectionCtx.buffer.writeImmutableBuffer(remainingBytes)
                            context.fireChannelRead(wrapInboundOut(.message(GRPCMessageIn(
                                remoteAddress: context.channel.remoteAddress,
                                requestHeaders: initialHeaders,
                                payload: messageCollectionCtx.buffer
                            ))))
                            state = .handlingStream(initialHeaders: initialHeaders, messageCollectionCtx: nil)
                            didReadForPrevMessage = true
                        } else {
                            // The DATA frame contains fewer bytes than what we're looking for, so we just add all of them and wait for the next frame
                            messageCollectionCtx.buffer.writeBuffer(&dataFrameDataBuffer)
                            precondition(!dataFrame.endStream)
                            return
                        }
                    } else {
                        didReadForPrevMessage = false
                    }
                    // At this point, we've either read all of the previous payload's remaining bytes, or there was no previous payload in this DATA frame.
                    // Either way, we should now be at the beginning of a new frame
                    precondition(dataFrameDataBuffer.readableBytes >= 0 && !didReadForPrevMessage, "unexpectedly found empty DATA frame...")
                    while dataFrameDataBuffer.readableBytes > 0 {
                        precondition(state == .handlingStream(initialHeaders: initialHeaders, messageCollectionCtx: nil))
                        let messageCtx = decodeMessagePayload(from: &dataFrameDataBuffer, headers: initialHeaders)
                        precondition(messageCtx.numMissingPayloadBytes >= 0) // Make sure we haven't read more than we want to
                        // If there's payload byted missing, we must've reached the end of the current DATA frame
                        precondition(messageCtx.numMissingPayloadBytes > 0, implies: dataFrameDataBuffer.readableBytes == 0)
                        if messageCtx.numMissingPayloadBytes == 0 {
                            let messageIn = GRPCMessageIn(
                                remoteAddress: context.channel.remoteAddress,
                                requestHeaders: initialHeaders,
                                payload: messageCtx.buffer
                            )
                            context.fireChannelRead(wrapInboundOut(.message(messageIn)))
                            state = .handlingStream(initialHeaders: initialHeaders, messageCollectionCtx: nil)
                        } else {
                            // There's data missing
                            precondition(!dataFrame.endStream)
                            state = .handlingStream(initialHeaders: initialHeaders, messageCollectionCtx: messageCtx)
                        }
                    }
                    if dataFrame.endStream {
                        state = .closed
                        context.fireChannelRead(wrapInboundOut(.closeStream(reason: .client)))
                    }
                case .closed:
                    fatalError("Unreachable, already handled above.")
                }
            case .fileRegion(let fileRegion):
                fatalError("Got unexpected FileRegion when expecting ByteBuffer: \(fileRegion)")
            }
        case .headers(let headers):
            switch state {
            case .ready:
                self.state = .handlingStream(initialHeaders: headers.headers, messageCollectionCtx: nil)
                context.fireChannelRead(wrapInboundOut(.openStream(headers.headers)))
            case .handlingStream:
                // NOTE that this might in fact be a valid state after all, HEADERS frames can also be sent at the end of a request,
                // although the gRPC docs don't mention this so idk maybe they don't use that.
                // (They do use it for responses, but that doesn't apply here...)
                logger.error("Invalid state: received HEADERS frame when handling a stream.")
                self.state = .closed
                context.fireChannelRead(wrapInboundOut(.closeStream(reason: .invalidState)))
            case .closed:
                fatalError("Unreachable, already handled above.")
            }
        case let .ping(pingData, ack):
            context.writeAndFlush(wrapOutboundOut(.ping(pingData, ack: ack)), promise: nil)
        case let .rstStream(errorCode): // HTTP2ErrorCode
            logger.warning("received RST_STREAM (w/ error code \(errorCode). Closing channel in response.")
            context.close(mode: .all, promise: nil)
            // Note: The difference between the branches below (which all close the channel in response to receiving an unexpected frame)
            // and the branch above (which closes the channel in response to receiving a RST_STREAM frame) is that above we close because
            // we actually want to end the connection, whereas below we close because we received an invalid frame.
        case .windowUpdate:
            // clients like grpc-swift will send `windowUpdate`s which the spec doesn't officially mandate to support.
            // Ignoring them is a viable workaround
            break
        case .priority, .settings, .pushPromise, .goAway, .alternativeService, .origin:
            logger.error("Received unexpected frame: \(input). Closing stream in response.")
            self.state = .closed
            context.fireChannelRead(wrapInboundOut(.closeStream(reason: .invalidState)))
        }
    }
    
    
    /// Decodes a gRPC message payload from the specified buffer.
    /// - Note: This function operates on the assumption that the buffer's current reader index does in fact point to the beginning of a gRPC message.
    private func decodeMessagePayload(from buffer: inout ByteBuffer, headers: HPACKHeaders) -> MessageCollectionContext {
        let messageCompression = headers[.gRPCEncoding]
        precondition(messageCompression == nil, "Compression not yet supported")
        guard buffer.readableBytes >= 5 else {
            fatalError("Invalid input: buffers must consist of at least five bytes")
        }
        let isCompressed: Bool = buffer.readInteger(as: UInt8.self)! == 1
        let messageLength = Int(buffer.readInteger(endianness: .big, as: UInt32.self)!)
        let messageCtx = MessageCollectionContext(
            expectedPayloadSize: messageLength,
            compression: isCompressed ? messageCompression : nil
        )
        let payload = buffer.readSlice(length: min(messageLength, buffer.readableBytes))!
        messageCtx.buffer.writeImmutableBuffer(payload)
        return messageCtx
    }
}
