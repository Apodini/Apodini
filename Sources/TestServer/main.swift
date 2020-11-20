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
    
    var configure: some Configuration {
        APNSConfiguration("test")
    }
}

TestServer.main()
