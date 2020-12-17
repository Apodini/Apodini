//
//  TestWebService.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

@testable import Apodini
import Vapor
import NIO


struct TestWebService: Apodini.WebService {
    struct PrintGuard: SyncGuard {
        private let message: String?
        @_Request
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
    
    struct Greeter: Component {
        @_Request
        var req: Vapor.Request
        
        func handle() -> String {
            do {
                return try req.query.get(at: "name")
            } catch {
                return "World"
            }
        }
    }
    
    @PathParameter
    var birdID: Bird.IDValue
    
    var content: some Component {
        Text("Hello World! 👋")
            .response(EmojiMediator(emojis: "🎉"))
            .response(EmojiMediator())
            .guard(PrintGuard())
        Group("swift") {
            Text("Hello Swift! 💻")
                .response(EmojiMediator())
                .guard(PrintGuard())
            Group("5", "3") {
                Text("Hello Swift 5! 💻")
            }
        }.guard(PrintGuard("Someone is accessing Swift 😎!!"))
        Group("greet") {
            Greeter()
        }
        Group("api", "birds") {
            Create<Bird>()
                .operation(.create)
            Group($birdID) {
                Get<Bird>(id: $birdID).operation(.read)
                Update<Bird>(id: $birdID).operation(.update)
            }
        }
    }
    
    var configuration: Configuration {
        DatabaseConfiguration(.defaultMongoDB(Environment.get("DATABASE_URL") ?? "mongodb://localhost:27017/vapor_database"))
            .addMigrations(CreateBird())
    
    }
}

TestWebService.main()
