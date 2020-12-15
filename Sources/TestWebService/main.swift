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
        @UselessWrapper var name: String?
        var dynamics: Dynamics = ["surname": Parameter<String?>()]
        
        func handle() -> String {
            let surnameParameter: Parameter<String?>? = dynamics["surname"]
            
            return (name ?? "Unknown") + " " + (surnameParameter?.wrappedValue ?? "Unknown")
        }
    }
    
    @propertyWrapper
    struct UselessWrapper: DynamicProperty {
        @Parameter var name: String?
        
        var wrappedValue: String? {
            name
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
            Group("5") {
                Text("Hello Swift 5! 💻")
            }
        }.guard(PrintGuard("Someone is accessing Swift 😎!!"))
        Group("greet") {
            Greeter()
        }
    }
}

TestWebService.main()
