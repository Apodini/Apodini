import Vapor
import Fluent
import FluentSQLiteDriver

/// A `Configuration` used for Database Access
public class DatabaseConfiguration: Configuration {
    private let type: DatabaseType
    
    private var migrations: [Migration] = []
    
    private var connectionString: String = Environment.get("DATABASE_URL") ?? "mongodb://localhost:27017/vapor_database"
    
    /// Creates a new database configuration
    ///
    /// - Parameters:
    ///     - type: The database type. Possible types are MongoDB, SQLite
    public init(_ type: DatabaseType) {
        self.type = type
    }
    
    public func configure(_ app: Application) {
        do {
            let databases = app.databases
            
            switch type {
            case .mongo:
                try databases.use(.mongo(connectionString: self.connectionString), as: .mongo)
            case .sqlLite:
                databases.use(.sqlite(.memory), as: .sqlite)
            }
            app.migrations.add(migrations)
            try app.autoMigrate().wait()
        } catch(let error) {
            fatalError(error.localizedDescription)
        }
    }
    
    /// A modifier to specify the connection url to the initiated database
    ///
    /// - Parameters:
    ///     - connectionString: The connection string to the database in the correct format for the database used
    public func connectionString(_ connectionString: String) -> Self {
        self.connectionString = connectionString
        return self
    }
    
    /// A modifier to add one or more `Migrations` to the database. The given `Migrations` need to conform to the `Vapor.Migration ` class.
    ///
    /// - Parameters:
    ///     - migrations: One or more `Migration` objects that should be migrated by the database
    public func addMigrations(_ migrations: Migration...) -> Self {
        self.migrations.append(contentsOf: migrations)
        return self
    }
}

/// An enum which represents the database types supported by Apodini. 
public enum DatabaseType {
    case mongo, sqlLite
}
