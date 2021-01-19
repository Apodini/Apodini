//
//  TestWebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini
import NIO


struct SimpleError: Swift.Error {
    let message: String
}


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
        private let growth: Int
        
        @State var amount: Int = 1
        
        init(emojis: String = "✅", growth: Int = 1) {
            self.emojis = emojis
            self.growth = growth
        }
        
        
        func transform(content string: String) -> String {
            defer { amount *= growth }
            return "\(String(repeating: emojis, count: amount)) \(string) \(String(repeating: emojis, count: amount))"
        }
    }
    
    
    struct RandomNumberGenerator: InvocableHandler {
        class HandlerIdentifier: ScopedHandlerIdentifier<RandomNumberGenerator> {
            static let main = HandlerIdentifier("main")
        }
        let handlerId = HandlerIdentifier.main
        
        @Parameter var lowerBound: Int = 0
        @Parameter var upperBound: Int = .max
        
        func handle() throws -> Int {
            guard lowerBound <= upperBound else {
                throw SimpleError(message: "Invalid bounds: lowerBound (\(lowerBound)) must be <= upperBound (\(upperBound))")
            }
            return Int.random(in: lowerBound..<upperBound)
        }
    }
    
    
    struct NewGreeter: Handler {
        private var RHI = RemoteHandlerInvocationManager()
        
        @Parameter var name: String
        @Parameter var age: Int
        
        init(name: Parameter<String>) {
            self._name = name
        }
        
        func handle() throws -> EventLoopFuture<String> {
            RHI.invoke(
                RandomNumberGenerator.self,
                identifiedBy: .main,
                parameters: [.init(\.$upperBound, age)]
            )
            .map { randomNumber in
                "Hello \(name) of age \(age). Your lucky number is \(randomNumber)"
            }
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
    
    
    struct Auction: Handler {
        @Parameter var bid: UInt
        
        @Environment(\.connection) var connection: Connection
        
        @State var highestBid: UInt = 0
        
        static let minimumBid: UInt = 1000
        
        func handle() -> Response<String> {
            if connection.state == .open {
                if bid > highestBid {
                    highestBid = bid
                    return .send("accepted")
                } else {
                    return .send("denied")
                }
            } else {
                if highestBid >= Self.minimumBid {
                    return .final("sold")
                } else {
                    return .final("not sold")
                }
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
    
    struct Random: Handler {
        @Parameter var number = Int.random()
        
        func handle() -> Int {
            number
        }
    }

    struct UserHandler: Handler {
        @Parameter var userId: Int

        func handle() -> User {
            User(id: userId)
        }
    }

    @PathParameter var userId: Int
    @PathParameter var name: String
    
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
                .response(EmojiMediator())
        }
        Group("greet", "new", $name) {
            NewGreeter(name: $name)
        }
        Group {
            "user"
            $userId
        } content: {
            UserHandler(userId: $userId)
                .guard(PrintGuard())
                .description("Returns `User` by id")
        }
        Group("auction") {
            Auction()
                .response(EmojiMediator(emojis: "🤑", growth: 2))
        }
        Group("rand") {
            Random()
        }
        Group("random", "int") {
            RandomNumberGenerator()
        }
    }
}

try TestWebService.main()
