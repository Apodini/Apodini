//
//  Running.swift
//  
//
//  Created by Tim Gymnich on 22.12.20.
//
//
// This code is based on the Vapor project: https://github.com/vapor/vapor
//
// The MIT License (MIT)
//
// Copyright (c) 2020 Qutheory, LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


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
