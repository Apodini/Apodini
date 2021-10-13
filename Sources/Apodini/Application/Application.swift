//
//  Application.swift
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


import Logging
import NIO
import NIOConcurrencyHelpers
import Dispatch


/// Delegate methods related to application lifecycle
public protocol LifecycleHandler {
    /// server will boot
    func willBoot(_ application: Application) throws
    /// server did boot
    func didBoot(_ application: Application) throws
    /// server is shutting down
    func shutdown(_ application: Application)
}

extension LifecycleHandler {
    /// server will boot
    public func willBoot(_ application: Application) throws { }
    /// server did boot
    public func didBoot(_ application: Application) throws { }
    /// server is shutting down
    public func shutdown(_ application: Application) { }
}

extension Application {
    func map<T>(transform: (Application) -> T ) -> T {
        transform(self)
    }
}

/// Configuration and state of the application
public final class Application {
    private static var latestApplicationLogger: Logger?
    /// A global logger that can be used when no  `Application` instance is available.
    ///
    /// - Note: In `Handler`s you shpuld rely on the `Logger` injected in the `@Environment`.
    public static var logger: Logger {
        latestApplicationLogger ?? {
            var newLogger = Logger(label: "Pre-startup")
            #if DEBUG
            newLogger.logLevel = .debug
            #endif
            latestApplicationLogger = newLogger
            return newLogger
        }()
    }
    
    
    /// Decides how EventLoopGroups are created
    public let eventLoopGroupProvider: EventLoopGroupProvider
    /// The EventLoopGroup for the application
    public let eventLoopGroup: EventLoopGroup
    /// Enables swift extensions to declare "stored" properties for use in application configuration
    public var storage: Storage
    /// Used for logging
    public var logger: Logger
    private var didShutdown: Bool
    private var isBooted: Bool
    private var signalSources: [DispatchSourceSignal] = []

    /// Keeps track of all application lifecylce handlers
    public struct Lifecycle {
        var handlers: [LifecycleHandler]
        init() {
            self.handlers = []
        }

        /// add lifecycle handler
        public mutating func use(_ handler: LifecycleHandler) {
            self.handlers.append(handler)
        }
    }

    /// Keeps track of the application lifecylce
    public var lifecycle: Lifecycle

    /// Keeps track of shared locks
    public final class Locks {
        /// main lock
        public let main: Lock
        var storage: [ObjectIdentifier: Lock]

        init() {
            self.main = .init()
            self.storage = [:]
        }

        /// get lock for key
        public func lock<Key>(for key: Key.Type) -> Lock where Key: LockKey {
            self.main.lock()
            defer { self.main.unlock() }
            if let existing = self.storage[ObjectIdentifier(Key.self)] {
                return existing
            } else {
                let new = Lock()
                self.storage[ObjectIdentifier(Key.self)] = new
                return new
            }
        }
    }

    /// Holds the applications shared locks
    public var locks: Locks

    /// Holds the applications main lock
    public var sync: Lock {
        self.locks.main
    }

    /// Defines how EventLoopGroups are created
    public enum EventLoopGroupProvider {
        /// use shared EventLoopGroup
        case shared(EventLoopGroup)
        /// create new EventLoopGroup
        case createNew
    }

    /// Create a new application instance
    public init(_ eventLoopGroupProvider: EventLoopGroupProvider = .createNew) {
        self.eventLoopGroupProvider = eventLoopGroupProvider
        switch eventLoopGroupProvider {
        case .shared(let group):
            self.eventLoopGroup = group
        case .createNew:
            self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        }
        self.locks = .init()
        self.didShutdown = false
        
        self.logger = .init(label: "org.apodini.application")
        #if DEBUG
        self.logger.logLevel = .debug
        #endif
        Application.latestApplicationLogger = self.logger
        
        self.storage = .init(logger: self.logger)
        self.lifecycle = .init()
        self.isBooted = false
        self.core.initialize()
    }

    /// Run the application and wait for it to stop
    public func run() throws {
        do {
            try self.start()
            try self.running?.onStop.wait()
        } catch {
            self.logger.warning("\(error.localizedDescription)")
            throw error
        }
    }

    /// Run the application
    public func start() throws {
        try self.boot()
        // allow the server to be stopped or waited for
        let promise = eventLoopGroup.next().makePromise(of: Void.self)
        running = .start(using: promise)

        // setup signal sources for shutdown
        let signalQueue = DispatchQueue(label: "org.apodini.application.shutdown")
        func makeSignalSource(_ code: Int32) {
            let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
            source.setEventHandler {
                print() // clear ^C
                promise.succeed(())
            }
            source.resume()
            self.signalSources.append(source)
            signal(code, SIG_IGN)
        }
        makeSignalSource(SIGTERM)
        makeSignalSource(SIGINT)
    }

    /// Boot the application
    public func boot() throws {
        guard !self.isBooted else {
            return
        }
        self.isBooted = true
        try self.lifecycle.handlers.forEach { try $0.willBoot(self) }
        try self.lifecycle.handlers.forEach { try $0.didBoot(self) }
    }

    /// Stop the application
    public func shutdown() {
        assert(!self.didShutdown, "Application has already shut down")
        self.running?.stop()
        self.logger.debug("Application shutting down [pid=\(getpid())]")

        self.logger.trace("Shutting down providers")
        self.lifecycle.handlers.forEach { $0.shutdown(self) }
        self.lifecycle.handlers = []

        self.logger.trace("Clearing Application storage")
        self.storage.shutdown()
        self.storage.clear()

        switch self.eventLoopGroupProvider {
        case .shared:
            self.logger.trace("Running on shared EventLoopGroup. Not shutting down EventLoopGroup.")
        case .createNew:
            self.logger.trace("Shutting down EventLoopGroup")
            do {
                try self.eventLoopGroup.syncShutdownGracefully()
            } catch {
                self.logger.error("Shutting down EventLoopGroup failed: \(error)")
            }
        }

        self.didShutdown = true
        self.logger.trace("Application shutdown complete")

        self.signalSources.forEach { $0.cancel() } // clear refs
        self.signalSources = []
    }

    deinit {
        self.logger.trace("Application deinitialized, goodbye!")
        if !self.didShutdown {
            assertionFailure("Application.shutdown() was not called before Application deinitialized.")
        }
    }
}

/// Identifier for Locks
public protocol LockKey { }
