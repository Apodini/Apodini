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
        var request: ApodiniRequest
        
        
        init(_ message: String? = nil) {
            self.message = message
        }
        

        func check() {
            print("\(message?.description ?? request.description)")
        }
    }

    struct SomeStruct: Vapor.Content {
        var someProp: Int
        var optionalInt: Int?
        var optinalString: String?
        var reqDouble: Double
    }

    struct SomeComp: Component {
        @Parameter
        var name: String?

        func handle() -> SomeStruct {
            SomeStruct(someProp: 4, reqDouble: 5.0)
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
        @Parameter("PathName", .http(.path)) var name: String

        @Parameter("greetParam")
        var greet: String?

        func handle() -> String {
            "\(greet ?? "Hello") \(name)"
        }
    }

    struct User: Codable {
        var id: Int
    }

    struct UserHandler: Component {
        @Parameter
        var userId: Int

        func handle() -> User {
            User(id: userId)
        }
    }

    @PathParameter var userId: Int
    
    var content: some Component {
        Greeter()
            .response(EmojiMediator(emojis: "🎉"))
        Group("swift") {
            Group("5", "3") {
                Text("Hello Swift 5! 💻")
            }
        }
        Group("openApiTest") {
            SomeComp()
        }
        Group("user", $userId) {
            UserHandler(userId: $userId)
                .guard(PrintGuard())
        }
    }
}

TestWebService.main()
