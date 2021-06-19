import Fluent
import Apodini
import NIOSSL
@_implementationOnly import FluentSQLiteDriver
@_implementationOnly import FluentMySQLDriver
@_implementationOnly import FluentPostgresDriver
@_implementationOnly import FluentMongoDriver
import Foundation

/// A `Configuration` used for Database Access
public final class DatabaseConfiguration: Configuration {
    private let type: DatabaseType
    private(set) var migrations: [Migration] = []
    public var databaseID: DatabaseID {
        switch type {
        case .defaultMongoDB:
            return .mongo
        case .defaultMySQL, .mySQL:
            return .mysql
        case .defaultPostgreSQL, .postgreSQL:
            return .psql
        case .sqlite:
            return .sqlite
        }
    }
    
    /// Initializes a new database configuration
    ///
    /// - Parameters:
    ///     - type: The database type specified by an `DatabaseType`object. 
    public init(_ type: DatabaseType) {
        self.type = type
    }
    
    public func configure(_ app: Application) {
        do {
            let databases = app.databases
            let factory = try databaseFactory(for: self.type)
            databases.use(factory, as: databaseID)
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
    public func addMigrations(_ migrations: Migration...) -> Self {
        self.migrations.append(contentsOf: migrations)
        return self
    }
    
    private func databaseFactory(for type: DatabaseType) throws -> Fluent.DatabaseConfigurationFactory {
        switch type {
        case .defaultMongoDB(let conString):
            return try .mongo(connectionString: conString)
        case .sqlite(let config):
            return .sqlite(.apply(config))
        case .defaultPostgreSQL(let conString):
            return try .postgres(url: conString)
        case let .postgreSQL(hostName, port, username, password, database, configuration):
            let config = PostgresConfiguration(hostname: hostName,
                                               port: port,
                                               username: username,
                                               password: password,
                                               database: database,
                                               tlsConfiguration: configuration)
            return .postgres(hostname: hostName, username: username, password: password, database: database)
        case .defaultMySQL(let conString):
            return try .mysql(url: conString)
        case let .mySQL(hostname, username, password, database, tlsConfig):
            let config = MySQLConfiguration(hostname: hostname,
                                            username: username,
                                            password: password,
                                            database: database,
                                            tlsConfiguration: tlsConfig)
            return .mysql(configuration: config)
        }
    }
}
/// An enum specifying the configuration of the SQLite database type.
public enum SQLiteConfig {
    /// Creates the database in memory
    case memory
    /// Creates the database using the specified file.
    ///
    /// - Parameters:
    /// - path: The path to the file on which the database should saved on.
    case file(_ path: String)
}

/// An enum which represents the database types supported by Apodini. 
public enum DatabaseType {
    /// A database type for a default mongoDB configuration
    ///
    /// - Parameters:
    /// - connectionString: The URL-String the database will listen on.
    case defaultMongoDB(_ connectionString: String)
    /// A database type for a default postreSQL configuration
    ///
    /// - Parameters:
        /// - connectionString: The URL-String the database will listen on.
    case defaultPostgreSQL(_ connectionString: String)
    // swiftlint:disable enum_case_associated_values_count
    /// A database type for a specified postreSQL configuration
    ///
    /// - Parameters:
        /// - hostname: The name of the database host.
        /// - username: The username of the database user.
        /// - port:     The port of the database.
        /// - password: The password of the database user.
        /// - database: The name of the database
        /// - configuration: The `TLSConfiguration` object  that should be used
    case postgreSQL(hostname: String, port: Int, username: String, password: String, database: String, configuration: TLSConfiguration)
    /// A database type for a specified sqLite configuration
    ///
    /// - Parameters:
        /// - config: A `SQLiteConfig` object to configure the sqliteDB.
    case sqlite(_ config: SQLiteConfig)
    /// A database type for a default mySQL configuration
    ///
    /// - Parameters:
    /// - connectionString: The URL-String the database will listen on.
    case defaultMySQL(_ connectionString: String)
    /// A database type for a specified mySQL configuration.
    /// Uses the `TLSConfiguration.forClient()` configuration.
    ///
    /// - Parameters:
        /// - hostname: The name of the database host.
        /// - username: The username of the database user.
        /// - password: The password of the database user.
        /// - database: The name of the database
        /// - configuration: A `TLSConfiguration` that should be used.
    case mySQL(_ hostname: String, username: String, password: String, database: String, configuration: TLSConfiguration)
}

/// An extension to the `Fluent.SQLiteConfiguration` to enable an initialization with an `Apodini.SQLiteConfig`.
extension SQLiteConfiguration {
    /// Enables an initialization of `SQLiteConfiguration` with an `Apodini.SQLiteConfig` object.
    ///
    /// - Parameters:
    ///     - config: A `Apodini.SQLiteConfig` object.
    static func apply(_ config: SQLiteConfig) -> SQLiteConfiguration {
        switch config {
        case .memory:
            return .init(storage: .memory)
        case .file(let path):
            return .init(storage: .file(path: path))
        }
    }
}
