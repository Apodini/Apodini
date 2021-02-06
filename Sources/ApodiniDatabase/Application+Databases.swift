//
//  Application+Databases.swift
//  
//
//  Created by Tim Gymnich on 23.12.20.
//

import Apodini
@_exported import FluentKit

extension Application {
    /// Used to store the applications databases
    public var databases: Databases {
        self.fluent.storage.databases
    }

    /// Used to store the applications database migrations
    public var migrations: Migrations {
        self.fluent.storage.migrations
    }

    /// Used to perfom database migrations
    public var migrator: Migrator {
        Migrator(
            databases: self.databases,
            migrations: self.migrations,
            logger: self.logger,
            on: self.eventLoopGroup.next()
        )
    }

    /// Automatically runs forward migrations without confirmation.
    /// This can be triggered by passing `--auto-migrate` flag.
    public func autoMigrate() -> EventLoopFuture<Void> {
        self.migrator.setupIfNeeded().flatMap {
            self.migrator.prepareBatch()
        }
    }

    /// Automatically runs reverse migrations without confirmation.
    /// This can be triggered by passing `--auto-revert` during boot.
    public func autoRevert() -> EventLoopFuture<Void> {
        self.migrator.setupIfNeeded().flatMap {
            self.migrator.revertAllBatches()
        }
    }

    /// default database
    public var database: Database {
        self.database(nil)
    }

    /// Get database with id
    public func database(_ id: DatabaseID?) -> Database {
        // swiftlint:disable force_unwrapping
        self.databases
            .database(
                id,
                logger: self.logger,
                on: self.eventLoopGroup.next(),
                history: self.fluent.history.historyEnabled ? self.fluent.history.history : nil
            )!
    }

    /// Keep track of the fluent database configuration
    public struct Fluent {
        final class Storage {
            let databases: Databases
            let migrations: Migrations

            init(threadPool: NIOThreadPool, on eventLoopGroup: EventLoopGroup) {
                self.databases = Databases(
                    threadPool: threadPool,
                    on: eventLoopGroup
                )
                self.migrations = .init()
            }
        }

        struct Key: StorageKey {
            // swiftlint:disable nesting
            typealias Value = Storage
        }

        struct Lifecycle: LifecycleHandler {
            func shutdown(_ application: Application) {
                application.databases.shutdown()
            }
        }

        let application: Application

        var storage: Storage {
            if self.application.storage[Key.self] == nil {
                self.initialize()
            }
            // swiftlint:disable force_unwrapping
            return self.application.storage[Key.self]!
        }

        func initialize() {
            self.application.storage[Key.self] = .init(
                threadPool: self.application.threadPool,
                on: self.application.eventLoopGroup
            )
            self.application.lifecycle.use(Lifecycle())
        }

        /// Database query history
        public var history: History {
            .init(fluent: self)
        }

        /// Database query history
        public struct History {
            let fluent: Fluent
        }
    }

    /// Used to keep track of the fluent database configutation
    public var fluent: Fluent {
        .init(application: self)
    }
}

struct RequestQueryHistory: StorageKey {
    typealias Value = QueryHistory
}

struct FluentHistoryKey: StorageKey {
    typealias Value = FluentHistory
}

struct FluentHistory {
    let enabled: Bool
}

extension Application.Fluent.History {
    var historyEnabled: Bool {
        storage[FluentHistoryKey.self]?.enabled ?? false
    }

    var storage: Storage {
        get {
            self.fluent.application.storage
        }
        nonmutating set {
            self.fluent.application.storage = newValue
        }
    }

    var history: QueryHistory? {
        storage[RequestQueryHistory.self]
    }

    /// The queries stored in this lifecycle history
    public var queries: [DatabaseQuery] {
        history?.queries ?? []
    }

    /// Start recording the query history
    public func start() {
        storage[FluentHistoryKey.self] = .init(enabled: true)
        storage[RequestQueryHistory.self] = .init()
    }

    /// Stop recording the query history
    public func stop() {
        storage[FluentHistoryKey.self] = .init(enabled: false)
    }

    /// Clear the stored query history
    public func clear() {
        storage[RequestQueryHistory.self] = .init()
    }
}
