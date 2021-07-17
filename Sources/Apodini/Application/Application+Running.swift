//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
//
// This code is based on the Vapor project: https://github.com/vapor/vapor
//
// SPDX-FileCopyrightText: 2020 Qutheory, LLC
//
// SPDX-License-Identifier: MIT
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
