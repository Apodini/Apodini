import Foundation
import NIO
import NIOHPACK
import Logging


protocol GRPCStreamRPCHandler: AnyObject {
    func handleStreamOpen(context: GRPCStreamConnectionContext)
    func handleStreamClose(context: GRPCStreamConnectionContext)
    func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut>
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



class GRPCStreamConnectionContextImpl: GRPCStreamConnectionContext {
    let eventLoop: EventLoop
    let initialRequestHeaders: HPACKHeaders
    let grpcMethodName: String
    private let rpcHandler: GRPCStreamRPCHandler
    private var isHandlingMessage = false
    
    init(eventLoop: EventLoop, initialRequestHeaders: HPACKHeaders, rpcHandler: GRPCStreamRPCHandler, grpcMethodName: String) {
        self.eventLoop = eventLoop
        self.initialRequestHeaders = initialRequestHeaders
        self.rpcHandler = rpcHandler
        self.grpcMethodName = grpcMethodName
    }
    
    func handleStreamOpen() {
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
    
    func handleStreamClose() {
        rpcHandler.handleStreamClose(context: self)
    }
}





class LKEventLoopFutureBasedQueue {
    private let eventLoop: EventLoop?
    private var lastMessageResponseFuture: EventLoopFuture<Void>?
    private var numQueuedHandlerCalls = 0
    private let logger: Logger
    
    init(eventLoop: EventLoop? = nil) {
        self.eventLoop = eventLoop
        self.logger = Logger(label: "[\(Self.self)]")
    }
    
    func submit<Result>(on eventLoop: EventLoop? = nil, tmp_debugDesc: String, _ task: @escaping () -> EventLoopFuture<Result>) -> EventLoopFuture<Result> {
        logger.notice("submit(desc: \(tmp_debugDesc), task: \(task))")
        guard let eventLoop = eventLoop ?? self.eventLoop else { // TODO ideally we'd have this take a non-nil EvenrLoop if none was passed to the iniitialiser, but that isn't possible :/
            fatalError("You need to specify an event loop, either here or in the initialzier!")
        }
        // TODO does any of this need to be thread-safe? looking especially at the numQueuedHandlerCalls thing...
        defer {
            self.lastMessageResponseFuture!.whenComplete { [/*TODO unowned?*/self] _ in
                self.numQueuedHandlerCalls -= 1
                precondition(self.numQueuedHandlerCalls >= 0)
                if self.numQueuedHandlerCalls == 0 {
                    self.lastMessageResponseFuture = nil
                }
            }
        }
        precondition((self.numQueuedHandlerCalls == 0) == (self.lastMessageResponseFuture == nil))
        
        guard let lastFuture = lastMessageResponseFuture else {
            precondition(numQueuedHandlerCalls == 0)
            let promise = eventLoop.makePromise(of: Void.self)
            self.numQueuedHandlerCalls += 1
            self.lastMessageResponseFuture = promise.futureResult
            logger.notice("Running task \(tmp_debugDesc). (no current task)")
            let taskFuture = task()
            taskFuture.whenComplete { _ in
                promise.succeed(())
                self.logger.notice("Task \(tmp_debugDesc) completed")
            }
            return taskFuture
        }
        let retvalPromise = eventLoop.makePromise(of: Result.self)
        self.numQueuedHandlerCalls += 1
        logger.notice("Queueing task \(tmp_debugDesc). (current task)")
        self.lastMessageResponseFuture = lastFuture.hop(to: eventLoop).flatMapAlways { _ -> EventLoopFuture<Void> in
            let promise = eventLoop.makePromise(of: Void.self)
            self.logger.notice("Running queued task \(tmp_debugDesc)")
            let taskFuture = task()
            taskFuture.cascade(to: retvalPromise)
            taskFuture.whenComplete { _ in
                promise.succeed(())
                self.logger.notice("Queued task \(tmp_debugDesc) completed")
            }
            return promise.futureResult
        }
        return retvalPromise.futureResult
    }
}
