//
//  TestWebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

@testable import Apodini
import Vapor
import NIO
import Runtime


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
        @Properties
        var properties: [String: Apodini.Property] = ["surname": Parameter<String?>()]
        
        @Parameter(.http(.path)) var name: String

        @Parameter var greet: String?
        
        func handle() -> String {
            let surnameParameter: Parameter<String?>? = _properties.typed(Parameter<String?>.self)["surname"]
            
            return "\(greet ?? "Hello") \(name) " + (surnameParameter?.wrappedValue ?? "Unknown")
        }
    }
    
    @propertyWrapper
    struct UselessWrapper: DynamicProperty {
        @Parameter var name: String?
        
        var wrappedValue: String? {
            name
        }
    }

    struct User: Codable {
        var id: Int
    }

    struct UserHandler: Component {
        @Parameter var userId: Int

        func handle() -> User {
            User(id: userId)
        }
    }

    @PathParameter var userId: Int
    
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
        Group("user", $userId) {
            UserHandler(userId: $userId)
                .guard(PrintGuard())
        }
    }
}

TestWebService.main()
