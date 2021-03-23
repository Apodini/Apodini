//
//  EventLoopFuture.swift
//  
//
//  Created by Paul Schmiedmayer on 1/12/21.
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
        file: StaticString = #file,
        line: UInt = #line,
        _ callback: @escaping (Value) throws -> EventLoopFuture<NewValue>
    ) -> EventLoopFuture<NewValue> {
        self.flatMap(file: file, line: line) { (value: Value) -> EventLoopFuture<NewValue> in
            do {
                return try callback(value)
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }
    }
}
