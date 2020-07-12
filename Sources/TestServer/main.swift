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
        Text("Hallo World! 👋")
            .response(EmojiMediator(emojis: "🎉"))
            .response(EmojiMediator())
        Group("swift") {
            Text("Hallo Swift! 💻")
                .response(EmojiMediator())
        }
    }
}

TestServer.main()
