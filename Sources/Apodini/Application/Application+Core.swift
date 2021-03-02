//
//  Application+Core.swift
//  
//
//  Created by Tim Gymnich on 22.12.20.
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
    /// Thread pool
    public var threadPool: NIOThreadPool {
        self.core.storage.threadPool
    }
    /// FileIO
    public var fileio: NonBlockingFileIO {
        .init(threadPool: self.threadPool)
    }
    /// Used to wait for the application to stop
    public var running: Running? {
        get { self.core.storage.running.current }
        set { self.core.storage.running.current = newValue }
    }

    internal var core: Core {
        .init(application: self)
    }

    /// Used to store core application settings / utils
    public struct Core {
        final class Storage {
            var threadPool: NIOThreadPool
            var running: Application.Running.Storage
            var directory: Directory
            init() {
                self.threadPool = NIOThreadPool(numberOfThreads: 1)
                self.threadPool.start()
                self.running = .init()
                self.directory = .detect()
            }
        }

        struct LifecycleHandler: Apodini.LifecycleHandler {
            func shutdown(_ application: Application) {
                // swiftlint:disable force_try
                try! application.threadPool.syncShutdownGracefully()
            }
        }

        struct Key: StorageKey {
            // swiftlint:disable nesting
            typealias Value = Storage
        }

        let application: Application

        var storage: Storage {
            guard let storage = self.application.storage[Key.self] else {
                fatalError("Core not configured. Configure with app.core.initialize()")
            }
            return storage
        }

        func initialize() {
            self.application.storage[Key.self] = .init()
            self.application.lifecycle.use(LifecycleHandler())
        }
    }
}
