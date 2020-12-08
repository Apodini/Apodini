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
    
    
    mutating func inject(using request: Vapor.Request, with decoder: SemanticModelBuilder? = nil) throws {
        self.database = request.db
    }
}

//MARK: - Dummy property wrapper until pr is merged
@propertyWrapper
public struct Param_Id<T: Model>: RequestInjectable where T.IDValue: LosslessStringConvertible {
    private var id: T.IDValue?
    
    public var wrappedValue: T.IDValue {
        guard let id = id else {
            fatalError("You can only access the database while you handle a request")
        }
        return id
    }
    
    public init() {}
    
    mutating func inject(using request: Vapor.Request, with decoder: SemanticModelBuilder?) throws {
        self.id = request.parameters.get("id", as: T.IDValue.self)
    }
}


@propertyWrapper
struct _Query: RequestInjectable {
    mutating func inject(using request: Request, with decoder: SemanticModelBuilder?) throws {
        self.urlString = request.url.query
    }
    
    private var urlString: String?
    
    var wrappedValue: String {
        guard let urlString = urlString else {
            fatalError("You can only access the URL while you handle a request")
        }
        
        return urlString
    }
    
    init() {}
}
