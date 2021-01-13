//
//  TestWebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini


struct TestWebService: Apodini.WebService {
    struct PrintGuard: SyncGuard {
        private let message: String

        init(_ message: String = "PrintGuard 👋") {
            self.message = message
        }
        

        func check() {
            print(message)
        }
    }
    
    struct EmojiMediator: ResponseTransformer {
        private let emojis: String
        
        
        init(emojis: String = "✅") {
            self.emojis = emojis
        }
        
        
        func transform(content string: String) -> String {
            "\(emojis) \(string) \(emojis)"
        }
    }
    

    struct TraditionalGreeter: Handler {
        // one cannot change their gender, it must be provided
        @Parameter(.mutability(.constant)) var gender: String
        // one cannot change their surname, but it can be ommitted
        @Parameter(.mutability(.constant)) var surname: String = ""
        // one can switch between formal and informal greeting at any time
        @Parameter var name: String?
        
        @Environment(\.connection) var connection: Connection

        func handle() -> Response<String> {
            print(connection.state)
            if connection.state == .end {
                return .final("This is the end")
            }

            if let firstName = name {
                return .send("Hi, \(firstName)!")
            } else {
                return .send("Hello, \(gender == "male" ? "Mr." : "Mrs.") \(surname)")
            }
        }
    }
    
    @propertyWrapper
    struct UselessWrapper: DynamicProperty {
        @Parameter var name: String?
        
        var wrappedValue: String? {
            name
        }
    }

    struct User: Codable, ResponseTransformable {
        var id: Int
    }

    struct UserHandler: Handler {
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
            TraditionalGreeter()
                .serviceName("GreetService")
                .rpcName("greetMe")
                .serviceType(.clientStreaming)
                .response(EmojiMediator())
        }
        Group {
            "user"
            $userId
        } content: {
            UserHandler(userId: $userId)
                .guard(PrintGuard())
        }
    }

    var configuration: Configuration {
        HTTP2Configuration()
    }
}

try TestWebService.main()
