//
//  TestRESTServer.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini
import Vapor
import NIO
import FluentMongoDriver
import Fluent


struct TestServer: Apodini.Server {
    struct PrintGuard: SyncGuard {
        private let message: String?
        @Apodini.Request
        var request: Vapor.Request
        
        
        init(_ message: String? = nil) {
            self.message = message
        }
        
        
        func check() {
            request.logger.info("\(message?.description ?? request.description)")
        }
    }
    
    struct EmojiMediator: ResponseTransformer {
        private let emojis: String
        
        
        init(emojis: String = "✅") {
            self.emojis = emojis
        }
        
        
        func transform(response: String) -> String {
            "\(emojis) \(response) \(emojis)"
        }
    }
    
    struct AddBirdsComponent: Component {
        @Apodini.Database
        var database: Fluent.Database
        
        @Body
        var bird: Bird
        
        
        func handle() -> EventLoopFuture<[Bird]> {
            bird.save(on: database)
                .flatMap { _ in
                    Bird.query(on: database)
                        .all()
                }
        }
    }
    
    var content: some Component {
        Text("Hello World! 👋")
            .response(EmojiMediator(emojis: "🎉"))
            .response(EmojiMediator())
            .guard(PrintGuard())
        Group("swift") {
            Text("Hello Swift! 💻")
                .response(EmojiMediator())
                .guard(PrintGuard())
        }.guard(PrintGuard("Someone is accessing Swift 😎!!"))
        Group("api") {
            AddBirdsComponent()
                .httpMethod(.POST)
        }
    }
    
    var configuration: some Configuration {
        DatabaseConfiguration(.mongo)
            .connectionString("mongodb://localhost:27017/vapor_database")
            .addMigrations(CreateBird())
    }
}

TestServer.main()

//MARK:- Test Models
final class Bird: DatabaseModel {
    static var schema: String = "Birds"
    
    
    @ID
    var id: UUID?
    @Field(key: "name")
    var name: String
    @Field(key: "age")
    var age: Int
    
    
    init(name: String, age: Int) {
        self.id = nil
        self.name = name
        self.age = age
    }
    
    init() {}
}


struct CreateBird: Migration {
    func prepare(on database: Fluent.Database) -> EventLoopFuture<Void> {
        return database.schema(Bird.schema)
            .id()
            .field("name", .string, .required)
            .field("age", .int, .required)
            .create()
    }

    func revert(on database: Fluent.Database) -> EventLoopFuture<Void> {
        return database.schema(Bird.schema).delete()
    }
}

extension Bird: Equatable {
    static func == (lhs: Bird, rhs: Bird) -> Bool {
        var result = lhs.name == rhs.name && lhs.age == rhs.age
        
        if let lhsId = lhs.id, let rhsId = rhs.id {
            result = result && lhsId == rhsId
        }
        
        return result
    }
}
