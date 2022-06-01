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

/// Collects any errors in the root stream, forwards them to a promise and closes the whole network connection.
final class CollectErrorsAndCloseStreamHandler: ChannelInboundHandler, Sendable {
    typealias InboundIn = Never

    private let promise: EventLoopPromise<Void>
    
    init(promise: EventLoopPromise<Void>) {
        self.promise = promise
    }

    func channelInactive(context: ChannelHandlerContext) {
        self.promise.succeed(())
        context.fireChannelInactive()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        self.promise.fail(error)
        context.close(promise: nil)
    }
}
