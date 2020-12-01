//
//  File.swift
//  
//
//  Created by Felix Desiderato on 27.11.20.
//

import Foundation
import Vapor
import Fluent
import FluentSQLiteDriver
//MARK:- Database Model and Migration
public final class Bird: DatabaseModel {

    public static var schema: String = "Birds"

    @ID(key: .id)
    public var id: UUID?
    
    @Field(key: "name")
    public var name: String
    @Field(key: "age")
    public var age: Int
    
    
    init(name: String, age: Int) {
//        self.id = nil
        self.name = name
        self.age = age
    }
    
    required public init() {}
}

public struct CreateBird: Migration {
    public func prepare(on database: Fluent.Database) -> EventLoopFuture<Void> {
        return database.schema(Bird.schema)
            .id()
            .field("name", .string, .required)
            .field("age", .int, .required)
            .create()
    }

    public func revert(on database: Fluent.Database) -> EventLoopFuture<Void> {
        return database.schema(Bird.schema).delete()
    }
    public init() {}
}

extension Bird: Equatable {
    public static func == (lhs: Bird, rhs: Bird) -> Bool {
        var result = lhs.name == rhs.name && lhs.age == rhs.age
        
        if let lhsId = lhs.id, let rhsId = rhs.id {
            result = result && lhsId == rhsId
        }
        
        return result
    }
}

public protocol DatabaseModel: Content, Model {
    
    
}




