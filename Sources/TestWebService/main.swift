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

    struct Greeter: Handler {
        @Properties
        var properties: [String: Apodini.Property] = ["surname": Parameter<String?>()]

        @Parameter(.http(.path))
        var name: String

        @Parameter
        var greet: String?

        func handle() -> String {
            let surnameParameter: Parameter<String?>? = _properties.typed(Parameter<String?>.self)["surname"]

            return "\(greet ?? "Hello") \(name) " + (surnameParameter?.wrappedValue ?? "Unknown")
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
                return .end
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

    struct UserHandler: Handler {
        @Parameter var userId: Int
        @Parameter var userName: String?

        func handle() -> User {
            User(id: userId, name: userName ?? "asdf", hasan: [Hasan(type: "SA", name: ["AS"]), Hasan(type: "AS", name: ["SA"])])
        }
    }


    struct Book: Codable, ResponseTransformable {
        var name: String
        var id: String
    }

    struct BookHandler: Handler {
        @Parameter var bookName: String

        func handle() -> Book {
            Book(name: bookName, id: "20")
        }
    }


    struct Hasan: Codable, ResponseTransformable {
        var type: String
        var name: [String]
    }

    struct User: Codable, ResponseTransformable {
        var id: Int
        var name: String
        var hasan: [Hasan]
    }

    struct AuthorHandler: Handler {
        @Parameter var bookName: String

        func handle() -> [User]? {
            [User(id: 15, name: "Eko", hasan: [Hasan(type: "sa", name: ["SA", "AS"])])]
        }
    }

    @PathParameter var userId: Int

    var content: some Component {
//        Text("Hello World! 👋")
//                .response(EmojiMediator(emojis: "🎉"))
//            .response(EmojiMediator())
//            .guard(PrintGuard())
//        Group("Desc") {
//            Text("123123").response(EmojiMediator(emojis: "🎉")).response(EmojiMediator())
//        }
        Group("Book") {
            Text("SA")
            // BookHandler()

            Group("authors") {
                AuthorHandler()
            }
        }
//        Group("swift") {
//            Group("FavCount") {
//                Group("Desc") {
//                    Text("1234")
//                }
//                Group("Name") {
//                    Text("123")
//                }
//            }
//            Group("Desc") {
//                Text("Hello Swift! 💻")
//            }
//                .response(EmojiMediator())
//                .guard(PrintGuard())
//            Group("5", "3") {
//                Text("Hello Swift 5! 💻")
//            }
//        } // .guard(PrintGuard("Someone is accessing Swift 😎!!"))
//        Group("greet") {
//            Greeter()
//                    .serviceName("GreetService")
//                    .rpcName("greetMe")
//                    .response(EmojiMediator())
//        }
//        Group("Users") {
//            Group("user") {
//                UserHandler()
//                // .guard(PrintGuard())
//            }
//        }
    }
}

try TestWebService.main()
