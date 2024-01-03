//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import NIO

extension EventLoopFuture {
    /// When the current EventLoopFuture<Value> is fulfilled, run the provided callback, which will provide a new EventLoopFuture.
    /// The provided callback may optionally `throw`.
    ///
    /// This allows you to dynamically dispatch new asynchronous tasks as phases in a longer series of processing steps.
    /// Note that you can use the results of the current EventLoopFuture<Value> when determining how to dispatch the next operation.
    ///
    /// If your callback function throws, the returned `EventLoopFuture` will error.
    ///
    /// - parameters:
    ///     - callback: Function that will receive the value of this EventLoopFuture and return a new EventLoopFuture. The provided `callback` may optionally `throw`.
    /// - returns: A future that will receive the eventual value.
    @inlinable
    func flatMapThrowing<NewValue>(
        _ callback: @escaping (Value) throws -> EventLoopFuture<NewValue>
    ) -> EventLoopFuture<NewValue> {
        self.flatMap { (value: Value) -> EventLoopFuture<NewValue> in
            do {
                return try callback(value)
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    /// Maps the future into another future, giving the caller the opportunity to map both success and failure values
    public func flatMapAlways<NewValue>(
        file: StaticString = #file,
        line: UInt = #line,
        _ block: @escaping (Result<Value, any Error>) -> EventLoopFuture<NewValue>
    ) -> EventLoopFuture<NewValue> {
        let promise = self.eventLoop.makePromise(of: NewValue.self, file: file, line: line)
        self.whenComplete { block($0).cascade(to: promise) }
        return promise.futureResult
    }
    
    /// Runs the specified block when the future is completed, regardless of whether the result is a success or a failure
    public func inspect(_ block: @escaping (Result<Value, any Error>) -> Void) -> EventLoopFuture<Value> {
        self.whenComplete(block)
        return self
    }
    
    /// Runs the specified block when the future succeeds
    public func inspectSuccess(_ block: @escaping (Value) -> Void) -> EventLoopFuture<Value> {
        self.whenSuccess(block)
        return self
    }
    
    /// Runs the specified block when the future fails
    public func inspectFailure(_ block: @escaping (any Error) -> Void) -> EventLoopFuture<Value> {
        self.whenFailure(block)
        return self
    }
}
