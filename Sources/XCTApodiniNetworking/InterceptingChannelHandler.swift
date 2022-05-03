//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIO
import XCTest
import ApodiniUtils


#if DEBUG || RELEASE_TESTING

/// A `ChannelOutboundHandler` intended to be used on an `EmbeddedChannel`, for tracing the outbound data sent over the channel.
public class OutboundInterceptingChannelHandler<T>: ChannelOutboundHandler {
    public typealias OutboundIn = T
    public typealias OutboundOut = T
    
    private let closeExpectation: XCTestExpectation?
    public private(set) var interceptedData: [T] = []
    private(set) var nextInterceptedDataHandler: ((T) -> Void)?
    
//    /// The expectation which should be fulfilled the next time data is written to the channel.
//    public var nextWriteExpectation: XCTestExpectation?
    
    /// - parameter closeExpectation: An XCTestExpectation which will be fulfilled when the channel is closed.
    public init(closeExpectation: XCTestExpectation? = nil) {
        self.closeExpectation = closeExpectation
    }
    
    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        interceptedData.append(unwrapOutboundIn(data))
        context.write(data, promise: promise)
        nextInterceptedDataHandler?(unwrapOutboundIn(data))
        nextInterceptedDataHandler = nil
    }
    
    public func close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
        context.close(mode: mode, promise: promise)
        closeExpectation?.fulfill()
    }
    
    
    public func setNextInterceptedDataHandler(_ handler: @escaping (T) -> Void) {
        self.nextInterceptedDataHandler = handler
    }
}


/// A `ChannelOutboundHandler` that consumes all data it receives, and does not forward anything to the next outbound handler.
public class OutboundSinkholeChannelHandler: ChannelOutboundHandler {
    public typealias OutboundIn = Never
    public typealias OutboundOut = Never
    
    public private(set) var receivedDataCount: UInt = 0
    
    public init() {}
    
    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        receivedDataCount += 1
        promise?.succeed(())
    }
}


/// A `ChannelInboundHandler` intended to be used on an `EmbeddedChannel`, for tracing the inbound data sent over the channel.
public class InboundInterceptingChannelHandler<T>: ChannelInboundHandler {
    public typealias InboundIn = T
    public typealias InboundOut = T
    
    public private(set) var interceptedData: [T] = []
    
    public init() {}
    
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        interceptedData.append(unwrapInboundIn(data))
        context.fireChannelRead(data)
    }
}

#endif // DEBUG || RELEASE_TESTING
