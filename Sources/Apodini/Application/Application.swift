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

import Logging
import NIO
import NIOConcurrencyHelpers
import Dispatch


/// Delegate methods related to application lifecycle
public protocol LifecycleHandler {
    /// WebService finished startup.
    func didStartup(_ application: Application) throws
    /// server did boot
    func didBoot(_ application: Application) throws
    /// server is shutting down
    func shutdown(_ application: Application) throws
    /// Allows interested parties to apply changes to the web service's endpoints.
    /// This function is primarily intended to give components that integrate with Apodini the ability to "disable" individual endpoints
    /// (e.g. by returning, for these specific endpoints, an empty array).
    /// This function is called once for every endpoint-interfaceExporter combination.
    func map<IE: InterfaceExporter>(endpoint: AnyEndpoint, app: Application, for interfaceExporter: IE) throws -> [AnyEndpoint]
}


extension LifecycleHandler {
    /// WebService finished startup.
    public func didStartup(_ application: Application) throws {}
    /// server did boot
    public func didBoot(_ application: Application) throws {}
    /// server is shutting down
    public func shutdown(_ application: Application) throws {}
    /// Allows interested parties to apply changes to the web service's endpoints.
    public func map<IE: InterfaceExporter>(endpoint: AnyEndpoint, app: Application, for interfaceExporter: IE) throws -> [AnyEndpoint] {
        [endpoint]
    }
}


/// Configuration and state of the application
public final class Application {
    private static var latestApplicationLogger: Logger?
    /// A global logger that can be used when no  `Application` instance is available.
    ///
    /// - Note: In `Handler`s you should rely on the `Logger` injected in the `@Environment`.
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

    /// Keeps track of all application lifecycle handlers
    public struct Lifecycle {
        private(set) var handlers: [any LifecycleHandler]
        init() {
            handlers = []
        }

        /// add lifecycle handler
        public mutating func use(_ handler: any LifecycleHandler) {
            handlers.append(handler)
        }
        
        /// Calls `-shutdown` on all handlers (in reverse order of registration), and removes them from the lifecycle
        mutating func shutdown(app: Application) {
            for handler in handlers.reversed() {
                do {
                    try handler.shutdown(app)
                } catch {
                    app.logger.error("Error during lifecycle-shutdown: \(error)")
                }
            }
            handlers.removeAll()
        }
    }

    /// Keeps track of the application lifecycle
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

    /// Signal that the web service started up.
    public func signalStartup() throws {
        for handler in lifecycle.handlers {
            try handler.didStartup(self)
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
        try self.lifecycle.handlers.forEach { try $0.didBoot(self) }
    }

    /// Stop the application
    public func shutdown() {
        assert(!self.didShutdown, "Application has already shut down")
        self.running?.stop()
        self.logger.debug("Application shutting down [pid=\(getpid())]")

        self.logger.trace("Shutting down lifecycle handlers")
        self.lifecycle.shutdown(app: self)

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
