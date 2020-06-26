//
//  Database.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO


public protocol Model {
    static var tableName: String { get }
}


public protocol Database: AnyObject {
    func store<M: Model>(_ model: M, on eventLoop: EventLoop) -> EventLoopFuture<M>
    func fetch<M: Model>(on eventLoop: EventLoop) -> EventLoopFuture<[M]>
}


@propertyWrapper
public class CurrentDatabase<D: Database>: RequestInjectable {
    private var database: D?
    
    
    public var wrappedValue: D {
        guard let database = database else {
            fatalError("You can only access the database while you handle a request")
        }
        
        return database
    }
    
    
    public init() { }
    
    
    func inject(using request: Request) throws {
        guard let database = request.context.database as? D else {
            throw HTTPError.internalServerError(reason: "Expected a database with the type of \(D.self)")
        }
        
        self.database = database
    }
    
    func disconnect() {
        self.database = nil
    }
}
