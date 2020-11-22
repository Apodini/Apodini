//
//  File.swift
//  
//
//  Created by Felix Desiderato on 21.11.20.
//
import Vapor
import Fluent

public class DatabaseConfiguration: Configuration {
    
    private let type: DatabaseType
    
    private var migrations: [Migration] = []
    
    private var connectionString: String = Environment.get("DATABASE_URL") ?? "mongodb://localhost:27017/vapor_database"
    
    public init(_ text: String) {
        self.type = .mongo
    }
    
    public init(_ type: DatabaseType) {
        self.type = type
    }
    
    public func configure(_ app: Application) {
        do {
            let databases = app.databases
            
            switch type {
            case .mongo:
                try databases.use(.mongo(connectionString: self.connectionString), as: .mongo)
                break
            default:
                break
            }
            app.migrations.add(migrations)
            try app.autoMigrate().wait()
        } catch(let error) {
            fatalError(error.localizedDescription)
        }
    }
    
    public func connectionString(_ string: String) -> Self {
        self.connectionString = string
//        self.connectionString = Environment.get("DATABASE_URL") ?? "mongodb://localhost:27017/vapor_database"
        return self
    }
    
    public func addMigrations(_ migrations: Migration...) -> Self {
        self.migrations = migrations
        return self
    }
}

public enum DatabaseType {
    case mongo, sqlLite
}

public protocol DatabaseModel: Model, Content {}
