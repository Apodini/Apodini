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
        @Parameter(.mutability(.constant)) var name: String?
        
        func handle() -> String {
            return name ?? "World"
        }
    }
    
    
    var content: some Component {
        Text("Hello World! 👋")
        Group("swift") {
            Text("Hello Swift! 💻")
        
            Group("bye") {
                Text("Bye! 👋")
//                    .webSocketOnSuccess(.close())
//                    .httpMethod(.DELETE)
//                    .webSocketOnError(.default)
            }
        }
//        .webSocketOnError(.close())
//        .httpMethod(.POST)
        Group("greet") {
            Greeter()
        }
    }
}

TestWebService.main()
