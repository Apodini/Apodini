//
//  Database.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
import protocol Fluent.Database


@propertyWrapper
// swiftlint:disable:next type_name
struct _Database: RequestInjectable {
    private var database: Fluent.Database?
    
    
    var wrappedValue: Fluent.Database {
        guard let database = database else {
            fatalError("You can only access the database while you handle a request")
        }
        
        return database
    }
    
    
    init() { }

    mutating func inject(using request: Request) throws {
        guard let database = request.database?() else {
            fatalError("Cannot inject database because the request does not contain a database")
        }
        self.database = database
    }
}
