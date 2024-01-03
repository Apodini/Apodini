//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import FluentKit
import Apodini

// swiftlint:disable discouraged_optional_boolean

/// A `Configuration` used for Database Access
public final class DatabaseConfiguration: Configuration {
    private let databaseConfiguration: FluentKit.DatabaseConfigurationFactory
    private let databaseID: DatabaseID
    private let isDefault: Bool?
    private(set) var migrations: [any Migration] = []
    
    
    /// Initializes a new database configuration
    ///
    /// - Parameters:
    ///     - type: The database type specified by an `DatabaseType`object.
    public init(
        _ databaseConfiguration: FluentKit.DatabaseConfigurationFactory,
        as databaseID: DatabaseID,
        isDefault: Bool? = nil,
        migrations: [any Migration] = []
    ) {
        self.databaseConfiguration = databaseConfiguration
        self.databaseID = databaseID
        self.isDefault = isDefault
    }
    
    
    public func configure(_ app: Application) {
        do {
            let databases = app.databases
            databases.use(databaseConfiguration, as: databaseID, isDefault: isDefault)
            app.migrations.add(migrations)
            try app.autoMigrate().wait()
        } catch {
            fatalError("An error occured while configuring the database. Error: \(error.localizedDescription)")
        }
    }
    
    /// A modifier to add one or more `Migrations` to the database. The given `Migrations` need to conform to the `Vapor.Migration ` class.
    ///
    /// - Parameters:
    ///     - migrations: One or more `Migration` objects that should be migrated by the database
    public func addMigrations(_ migrations: any Migration...) -> Self {
        self.migrations.append(contentsOf: migrations)
        return self
    }
}
