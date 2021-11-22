import Foundation
import NIO
import NIOHPACK


protocol GRPCv2StreamRPCHandler: AnyObject {
    func handleStreamOpen(context: GRPCv2StreamConnectionContext)
    func handleStreamClose(context: GRPCv2StreamConnectionContext)
    func handle(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut>
}



/// An open gRPC stream over which messages are sent
protocol GRPCv2StreamConnectionContext {
    /// The event loop associated with the connection. (... on which the connection is handled)
    var eventLoop: EventLoop { get }
    /// The HTTP/2 headers sent by the client, as part of the initial request creating this connection
    var initialRequestHeaders: HPACKHeaders { get }
    /// Fully qualified name of the method this connection is calling.
    var grpcMethodName: String { get }
}



class GRPCv2StreamConnectionContextImpl: GRPCv2StreamConnectionContext {
    let eventLoop: EventLoop
    let initialRequestHeaders: HPACKHeaders
    let grpcMethodName: String
    private let rpcHandler: GRPCv2StreamRPCHandler
    private var isHandlingMessage = false
    
    init(eventLoop: EventLoop, initialRequestHeaders: HPACKHeaders, rpcHandler: GRPCv2StreamRPCHandler, grpcMethodName: String) {
        self.eventLoop = eventLoop
        self.initialRequestHeaders = initialRequestHeaders
        self.rpcHandler = rpcHandler
        self.grpcMethodName = grpcMethodName
    }
    
    func handleStreamOpen() {
        rpcHandler.handleStreamOpen(context: self)
    }
    
    func handleMessage(_ message: GRPCv2MessageIn) -> EventLoopFuture<GRPCv2MessageOut> {
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
    
    init(eventLoop: EventLoop? = nil) {
        self.eventLoop = eventLoop
    }
    
    func submit<Result>(on eventLoop: EventLoop? = nil, _ task: @escaping () -> EventLoopFuture<Result>) -> EventLoopFuture<Result> {
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
