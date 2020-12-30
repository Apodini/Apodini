//
//  Running.swift
//  
//
//  Created by Tim Gymnich on 22.12.20.
//

import NIO


extension Application {
    /// Used to wait for the application to stop
    public struct Running {
        final class Storage {
            var current: Running?
            init() { }
        }

        /// Start waiting
        public static func start(using promise: EventLoopPromise<Void>) -> Self {
            self.init(promise: promise)
        }

        /// onStop
        public var onStop: EventLoopFuture<Void> {
            self.promise.futureResult
        }

        private let promise: EventLoopPromise<Void>

        /// Stops waiting
        public func stop() {
            self.promise.succeed(())
        }
    }
}
