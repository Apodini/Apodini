//
//  TestRESTServer.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini
import Vapor
import NIO


struct TestServer: Apodini.Server {
    struct PrintGuard: Guard {
        private let message: String?
        
        init(_ message: String? = nil) {
            self.message = message
        }
        
        func check(_ request: Vapor.Request) -> EventLoopFuture<Void> {
            print(message ?? request)
            return request.eventLoop.makeSucceededFuture(Void())
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
    }
}

TestServer.main()
