//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import NIO
import NIOHPACK
import NIOConcurrencyHelpers


/// Type that can handle events on a gRPC connection.
protocol GRPCStreamRPCHandler: AnyObject {
    /// The function that will be invoked when the stream is first opened
    func handleStreamOpen(context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut>?
    /// Invoked when the RPC connection receives an incoming client message.
    /// - returns: An EventLoopFuture that will eventually fulfill to a gRPC resonse message.
    func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut>
    /// Will be invoked when the stream is about to close.
    /// - returns: An optional EventLoopFuture. If the return value is `nil`, the connection will immediately be closed.
    ///     If the return value is not nil, the connection will be kept open until the future is fulfilled, the future's value will then be written to the connection, and the channel will be closed.
    func handleStreamClose(context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut>?
}

extension GRPCStreamRPCHandler {
    func handleStreamOpen(context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut>? {
        nil
    }
    func handleStreamClose(context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut>? {
        nil
    }
}


/// An open gRPC stream over which messages are sent
protocol GRPCStreamConnectionContext {
    /// The event loop associated with the connection. (... on which the connection is handled)
    var eventLoop: EventLoop { get }
    /// The HTTP/2 headers sent by the client, as part of the initial request creating this connection
    var initialRequestHeaders: HPACKHeaders { get }
    /// Fully qualified name of the method this connection is calling.
    var grpcMethodName: String { get }
}


class GRPCStreamConnectionContextImpl: GRPCStreamConnectionContext, Hashable {
    let eventLoop: EventLoop
    let initialRequestHeaders: HPACKHeaders
    let grpcMethodName: String
    private let rpcHandler: GRPCStreamRPCHandler
    private(set) var isHandlingMessage = false
    
    init(eventLoop: EventLoop, initialRequestHeaders: HPACKHeaders, rpcHandler: GRPCStreamRPCHandler, grpcMethodName: String) {
        self.eventLoop = eventLoop
        self.initialRequestHeaders = initialRequestHeaders
        self.rpcHandler = rpcHandler
        self.grpcMethodName = grpcMethodName
    }
    
    func handleStreamOpen() -> EventLoopFuture<GRPCMessageOut>? {
        rpcHandler.handleStreamOpen(context: self)
    }
    
    func handleMessage(_ message: GRPCMessageIn) -> EventLoopFuture<GRPCMessageOut> {
        precondition(!isHandlingMessage, "\(Self.self) cannot handle multiple messages simultaneously. Use the EventLoopFuturesQueue thing or whatever to deal w this.")
        isHandlingMessage = true
        let messageFuture = rpcHandler.handle(message: message, context: self)
        messageFuture.whenComplete { _ in
            self.isHandlingMessage = false
        }
        return messageFuture
    }
    
    func handleStreamClose() -> EventLoopFuture<GRPCMessageOut>? {
        rpcHandler.handleStreamClose(context: self)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    static func == (lhs: GRPCStreamConnectionContextImpl, rhs: GRPCStreamConnectionContextImpl) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}


/// A queue of `EventLoopFuture`s, which will be evaluated one after the other.
/// - Note: This is not always a useful or desirable thing, so use with caution.
class EventLoopFutureQueue {
    private let lock = Lock()
    private let eventLoop: EventLoop?
    private var lastMessageResponseFuture: EventLoopFuture<Void>?
    private var numQueuedHandlerCalls = 0
    
    init(eventLoop: EventLoop? = nil) {
        self.eventLoop = eventLoop
    }
    
    func submit<Result>(on eventLoop: EventLoop? = nil, _ task: @escaping () -> EventLoopFuture<Result>) -> EventLoopFuture<Result> {
        guard let eventLoop = eventLoop ?? self.eventLoop else {
            fatalError("You need to specify an event loop, either here or in the initializer!")
        }
        self.lock.lock()
        defer {
            self.lock.unlock()
            self.lastMessageResponseFuture!.whenComplete { [self] _ in
                self.lock.lock()
                self.numQueuedHandlerCalls -= 1
                precondition(self.numQueuedHandlerCalls >= 0)
                if self.numQueuedHandlerCalls == 0 {
                    self.lastMessageResponseFuture = nil
                }
                self.lock.unlock()
            }
        }
        precondition((self.numQueuedHandlerCalls == 0) == (self.lastMessageResponseFuture == nil))
        
        guard let lastFuture = lastMessageResponseFuture else {
            precondition(numQueuedHandlerCalls == 0)
            let promise = eventLoop.makePromise(of: Void.self)
            self.numQueuedHandlerCalls += 1
            self.lastMessageResponseFuture = promise.futureResult
            let taskFuture = task()
            taskFuture.whenComplete { _ in
                promise.succeed(())
            }
            return taskFuture
        }
        let retvalPromise = eventLoop.makePromise(of: Result.self)
        self.numQueuedHandlerCalls += 1
        self.lastMessageResponseFuture = lastFuture.hop(to: eventLoop).flatMapAlways { _ -> EventLoopFuture<Void> in
            let promise = eventLoop.makePromise(of: Void.self)
            let taskFuture = task()
            taskFuture.cascade(to: retvalPromise)
            taskFuture.whenComplete { _ in
                promise.succeed(())
            }
            return promise.futureResult
        }
        return retvalPromise.futureResult
    }
}
