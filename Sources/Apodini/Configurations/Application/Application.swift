//
//  Application.swift
//  
//
//  Created by Tim Gymnich on 22.12.20.
//

import Logging
import NIO
import NIOConcurrencyHelpers

/// Delegate methods related to application lifecycle
public protocol LifecycleHandler {
    func willBoot(_ application: Application) throws
    func didBoot(_ application: Application) throws
    func shutdown(_ application: Application)
}

extension LifecycleHandler {
    public func willBoot(_ application: Application) throws { }
    public func didBoot(_ application: Application) throws { }
    public func shutdown(_ application: Application) { }
}

extension Application {
    func map<T>(transform: (Application) -> T ) -> T {
        return transform(self)
    }
}

/// Configuration and state of the application
public final class Application {
    /// Decides how EventLoopGroups are created
    public let eventLoopGroupProvider: EventLoopGroupProvider
    /// The EventLoopGroup for the application
    public let eventLoopGroup: EventLoopGroup
    /// Enables swift extensions to declare "stored" properties for use in application configuration
    public var storage: Storage
    // Used for logging
    public var logger: Logger
    private var didShutdown: Bool
    private var isBooted: Bool

    /// Keeps track of all application lifecylce handlers
    public struct Lifecycle {
        var handlers: [LifecycleHandler]
        init() {
            self.handlers = []
        }

        public mutating func use(_ handler: LifecycleHandler) {
            self.handlers.append(handler)
        }
    }

    /// Keeps track of the application lifecylce
    public var lifecycle: Lifecycle

    /// Keeps track of shared locks
    public final class Locks {
        public let main: Lock
        var storage: [ObjectIdentifier: Lock]

        init() {
            self.main = .init()
            self.storage = [:]
        }

        public func lock<Key>(for key: Key.Type) -> Lock
        where Key: LockKey
        {
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
        case shared(EventLoopGroup)
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
            self.logger.report(error: error)
            throw error
        }
    }

    /// Run the application
    public func start() throws {
        try self.boot()
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
        self.logger.debug("Application shutting down")

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
