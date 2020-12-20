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
    
    public func update(_ object: Bird) {
        self.name = object.name
        self.age = object.age
        
    }
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
    func update(_ object: Self)
}

extension DatabaseModel {
    
    static func fieldKey(for string: String) -> FieldKey {
        return Self.keys.first(where: { $0.description == string })!
    }
}


public protocol TestModel: Model {
    associatedtype Input: Content
    associatedtype Output: Content
    
    init(_: Input) throws
    var output: Output { get }
    func update(_: Input)
}

public final class TestBird: TestModel {
    
    public struct _Input: Content {
        let name: String
        let age: Int
    }
    
    public struct _Output: Content {
        let id: String
        let name: String
        let age: Int
    }
    
    public typealias Input = _Input
    public typealias Output = _Output
    
    public static let schema: String = "Birds"
    
    @ID(key: .id) public var id: UUID?
    @Field(key: "name") public var name: String
    @Field(key: "age") public var age: Int
    
    public init() { }
    
    public init(id: UUID? = nil, name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
    }
    
    public init(_ input: Input) throws {
        self.name = input.name
        self.age = input.age
    }
    
    public func update(_ input: Input) {
        self.name = input.name
        self.age = input.age
    }
    
    public var output: Output {
        return .init(id: self.id!.uuidString, name: self.name, age: self.age)
    }
    
    
}




