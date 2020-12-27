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
        var request: Apodini.Request
        
        
        init(_ message: String? = nil) {
            self.message = message
        }
        

        func check() {
            print("\(message?.description ?? request.description)")
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
        @Parameter(.http(.path)) var name: String

        func handle() -> String {
            "Hello \(name)"
        }
    }
    
    struct TestMe: Job {
        func run() {
            print("TEST")
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
            Group("5", "3") {
                Text("Hello Swift 5! 💻")
            }
        }.guard(PrintGuard("Someone is accessing Swift 😎!!"))
        Group("greet") {
            Greeter()
        }
    }
    
    var configuration: Configuration {
        Schedule(TestMe(), on: "* * * * *", runs: 1)
    }
}

TestWebService.main()
