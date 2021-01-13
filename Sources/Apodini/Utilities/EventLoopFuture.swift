//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 1/12/21.
//

import NIO

extension EventLoopFuture {
    /// When the current `EventLoopFuture<Value>` is fulfilled, run the provided callback, which
    /// performs a synchronous computation and returns a new value of type `NewValue`. The provided
    /// callback may optionally `throw`.
    ///
    /// Operations performed in `flatMapThrowing` should not block, or they will block the entire
    /// event loop. `flatMapThrowing` is intended for use when you have a data-driven function that
    /// performs a simple data transformation that can potentially error.
    ///
    /// If your callback function throws, the returned `EventLoopFuture` will error.
    ///
    /// - parameters:
    ///     - callback: Function that will receive the value of this `EventLoopFuture` and return
    ///         a new value lifted into a new `EventLoopFuture`.
    /// - returns: A future that will receive the eventual value.
    @inlinable
    public func tryFlatMap<NewValue>(file: StaticString = #file,
                                     line: UInt = #line,
                                     _ callback: @escaping (Value) throws -> EventLoopFuture<NewValue>) -> EventLoopFuture<NewValue> {
        self.flatMap(file: file, line: line) { (value: Value) -> EventLoopFuture<NewValue> in
            do {
                return try callback(value)
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }
    }
}
