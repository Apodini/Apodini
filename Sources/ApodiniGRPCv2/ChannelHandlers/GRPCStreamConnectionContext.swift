import Foundation
import NIO
import NIOHPACK


protocol GRPCv2StreamRPCHandler: AnyObject {
    func handleStreamOpen(context: GRPCv2StreamConnectionContext)
    func handleStreamClose(context: GRPCv2StreamConnectionContext)
    func handle(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut>
}


/// An open gRPC stream over which messages are sent
class GRPCv2StreamConnectionContext {
    let eventLoop: EventLoop
    let initialRequestHeaders: HPACKHeaders
    let rpcHandler: GRPCv2StreamRPCHandler
    private var lastMessageResponseFuture: EventLoopFuture<Void>?
    private var numQueuedHandlerCalls = 0
    var tmp_method: String = ""
    
    init(eventLoop: EventLoop, initialRequestHeaders: HPACKHeaders, rpcHandler: GRPCv2StreamRPCHandler) {
        self.eventLoop = eventLoop
        self.initialRequestHeaders = initialRequestHeaders
        self.rpcHandler = rpcHandler
    }
    
    func handleStreamOpen() {
        rpcHandler.handleStreamOpen(context: self)
    }
    
    func handleStreamClose() {
        rpcHandler.handleStreamClose(context: self)
    }
    
    
    /// Handles the message, or adds it to the queue if the connection is already handling another message.
    func handle(message: GRPCv2MessageIn) -> EventLoopFuture<GRPCv2MessageOut> {
        // TODO does any of this need to be thread-safe? looking especially at the numQueuedHandlerCalls thing...
        defer {
            self.lastMessageResponseFuture!.whenComplete { [unowned self] _ in
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
            let rpcFuture = rpcHandler.handle(message: message, context: self)
            rpcFuture.whenComplete { _ in
                promise.succeed(())
            }
            return rpcFuture
        }
        let retvalPromise = eventLoop.makePromise(of: GRPCv2MessageOut.self)
        self.numQueuedHandlerCalls += 1
        self.lastMessageResponseFuture = lastFuture.flatMapAlways { [unowned self] _ -> EventLoopFuture<Void> in
            let promise = eventLoop.makePromise(of: Void.self)
            let rpcFuture = rpcHandler.handle(message: message, context: self)
            rpcFuture.cascade(to: retvalPromise)
            rpcFuture.whenComplete { _ in
                promise.succeed(())
            }
            return promise.futureResult
        }
        return retvalPromise.futureResult
    }
}
