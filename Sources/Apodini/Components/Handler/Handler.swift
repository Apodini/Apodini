//
//  Handler.swift
//  
//
//  Created by Paul Schmiedmayer on 1/11/21.
//

import NIO
#if compiler(>=5.4) && $AsyncAwait
import _NIOConcurrency
#endif

/// A `Handler` is a `Component` which defines an endpoint and can handle requests.
public protocol Handler: Component {
    /// The type that is returned from the `handle()` method when the component handles a request. The return type of the `handle` method is encoded into the response send out to the client.
    associatedtype Response: ResponseTransformable

    /// A function that is called when a request reaches the `Handler`
    #if compiler(>=5.4) && $AsyncAwait
    func handle() async throws -> Response
    #else
    func handle() throws -> Response
    #endif
}


extension Handler {
    /// By default, `Handler`s don't provide any further content
    public var content: some Component {
        EmptyComponent()
    }
}




// This extensions provides a helper for evaluating the `Handler`'s `handle` function.
// The function hides the syntactic difference between the newly introduced `async`
// version of `handle()` and the traditional, `EventLoopFuture`-based one.
extension Handler {
    #if compiler(>=5.4) && $AsyncAwait
    internal func evaluate(using eventLoop: EventLoop) -> EventLoopFuture<Response> {
        let promise: EventLoopPromise<Response> = eventLoop.makePromise()
        promise.completeWithAsync(self.handle)
        return promise.futureResult
    }
    #else
    internal func evaluate(using eventLoop: EventLoop) -> EventLoopFuture<Response> {
        let promise: EventLoopPromise<Response> = eventLoop.makePromise()
        do {
            let result = try self.handle()
            promise.succeed(result)
        } catch {
            promise.fail(error)
        }
        return promise.futureResult
    }
    #endif
}
