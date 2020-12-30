//
//  Core.swift
//  
//
//  Created by Tim Gymnich on 22.12.20.
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

            init() {
                self.threadPool = NIOThreadPool(numberOfThreads: 1)
                self.threadPool.start()
                self.running = .init()
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
