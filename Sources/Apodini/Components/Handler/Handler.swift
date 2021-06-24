//
//  Handler.swift
//  
//
//  Created by Paul Schmiedmayer on 1/11/21.
//

import NIO
#if compiler(>=5.5) && $APODINI_EXPERIMENTAL_ASYNC_AWAIT
import _NIOConcurrency
#endif

/// A `Handler` is a `Component` which defines an endpoint and can handle requests.
public protocol Handler: HandlerMetadataNamespace, Component {
    /// The type that is returned from the `handle()` method when the component handles a request. The return type of the `handle` method is encoded into the response send out to the client.
    associatedtype Response: ResponseTransformable

    typealias Metadata = AnyHandlerMetadata

    /// A function that is called when a request reaches the `Handler`
    #if compiler(>=5.5) && $APODINI_EXPERIMENTAL_ASYNC_AWAIT
    @available(macOS 12, *)
    func handle() async throws -> Response
    #else
    func handle() throws -> Response
    #endif
}

// MARK: Metadata DSL
public extension Handler {
    /// Handlers have an empty `AnyHandlerMetadata` by default.
    var metadata: AnyHandlerMetadata {
        Empty()
    }
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
    #if compiler(>=5.5) && $APODINI_EXPERIMENTAL_ASYNC_AWAIT
    @available(macOS 12, *)
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
