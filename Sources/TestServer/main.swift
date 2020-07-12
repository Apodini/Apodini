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
    struct EmojiMediator: ResponseMediator {
        let emojiString: String
        
        init(_ response: String) {
            emojiString = "✅ \(response) ✅"
        }
        
        func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
            emojiString.encodeResponse(for: request)
        }
    }
    
    
    var content: some Component {
        Text("Hallo World! 👋")
            .response(EmojiMediator.self)
        Group("swift") {
            Text("Hallo Swift! 💻")
                .response(EmojiMediator.self)
        }
    }
}

TestServer.main()
