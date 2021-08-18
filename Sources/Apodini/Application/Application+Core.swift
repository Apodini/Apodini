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
            func shutdown(_ application: Application) throws {
                try application.threadPool.syncShutdownGracefully()
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
