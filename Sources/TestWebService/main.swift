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
        
        struct ReturnStruct: Vapor.Content {
            var someProp: Int
        }
        
        func handle() -> ReturnStruct {
            return ReturnStruct(someProp: 5)

        }
    }
    
    struct TestHandler: Component {
        @Parameter("someId", .http(.path))
        var id: Int
        
        func handle() -> String {
            "Hello \(id)"
        }
    }
    
    @PathParameter
    var name: String
    
    var content: some Component {
        Text("Hello World! 👋")
            .response(EmojiMediator(emojis: "🎉"))
            .response(EmojiMediator())
            .guard(PrintGuard())
            .operation(.delete)
        Group("swift") {
            Group("5") {
                Text("Hello Swift 5! 💻")
            }
        }
        Group("greet", $name) {
            Greeter()
            .operation(.update)
            TestHandler()
        }
    }
}

TestWebService.main()
