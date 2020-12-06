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
    
    
    var content: some Component {
        Text("Hello World! 👋")
            .response(EmojiMediator(emojis: "🎉"))
            .response(EmojiMediator())
            .guard(PrintGuard())
        Group("swift") {
            Text("Hello Swift! 💻")
                .response(EmojiMediator())
                .guard(PrintGuard())
        
            Group("bye") {
                Text("Bye! 👋")
                    .webSocketOnSuccess(.close())
                    .httpMethod(.DELETE)
                    .webSocketOnError(.default)
            }
        }.guard(PrintGuard("Someone is accessing Swift 😎!!"))
        .webSocketOnError(.close())
        .httpMethod(.POST)
        Group("greet") {
            Greeter()
        }
    }
}

TestWebService.main()
