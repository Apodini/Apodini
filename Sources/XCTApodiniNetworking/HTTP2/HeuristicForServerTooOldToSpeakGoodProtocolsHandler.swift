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

final class HeuristicForServerTooOldToSpeakGoodProtocolsHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer

    enum Error: Swift.Error {
        case serverDoesNotSpeakHTTP2
    }

    var bytesSeen = 0

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)
        bytesSeen += buffer.readableBytes
        context.fireChannelRead(data)
    }

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        if self.bytesSeen == 0 {
            if case let event = event as? TLSUserEvent, event == .shutdownCompleted || event == .handshakeCompleted(negotiatedProtocol: nil) {
                context.fireErrorCaught(Error.serverDoesNotSpeakHTTP2)
                return
            }
        }
        context.fireUserInboundEventTriggered(event)
    }

    func errorCaught(context: ChannelHandlerContext, error: Swift.Error) {
        if self.bytesSeen == 0 {
            switch error {
            case NIOSSLError.uncleanShutdown,
                 is IOError where (error as! IOError).errnoCode == ECONNRESET:
                // this is very highly likely a server doesn't speak HTTP/2 problem
                context.fireErrorCaught(Error.serverDoesNotSpeakHTTP2)
                return
            default:
                ()
            }
        }
        context.fireErrorCaught(error)
    }
}
