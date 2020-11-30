//
//  Database.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import Vapor
import Fluent


@propertyWrapper
public struct Database: RequestInjectable {
    private var database: Fluent.Database?
    
    
    public var wrappedValue: Fluent.Database {
        guard let database = database else {
            fatalError("You can only access the database while you handle a request")
        }
        
        return database
    }
    
    
    public init() { }
    
    
    mutating func inject(using request: Vapor.Request, with decoder: RequestInjectableDecoder? = nil) throws {
        self.database = request.db
    }
}
