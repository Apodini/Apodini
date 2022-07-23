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

import Apodini
import FluentKit


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
                on: self.eventLoopGroup.next()
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
            func shutdown(_ application: Application) throws {
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
    }

    /// Used to keep track of the fluent database configuration
    public var fluent: Fluent {
        .init(application: self)
    }
}
