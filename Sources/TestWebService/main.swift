//
//  TestWebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini
import NIO
import ApodiniDeployBuildSupport
import DeploymentTargetLocalhostRuntimeSupport
import DeploymentTargetAWSLambdaRuntime


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
            static let main = HandlerIdentifier("main_2")
        }
        let handlerId = HandlerIdentifier.main
        
        @Parameter var lowerBound: Int = 0
        @Parameter var upperBound: Int = .max
        
        func handle() throws -> Int {
            print("-[\(Self.self) \(#function)] executed in pid \(getpid())")
            guard lowerBound <= upperBound else {
                throw SimpleError(message: "Invalid bounds: lowerBound (\(lowerBound)) must be <= upperBound (\(upperBound))")
            }
            return Int.random(in: lowerBound..<upperBound)
        }
    }
    
    
    struct Greeter: IdentifiableHandler {
        private var RHI = RemoteHandlerInvocationManager()
        
        @Parameter var name: String
        @Parameter var age: Int
        
        static let id = ScopedHandlerIdentifier<Self>("owooo_2")
        let handlerId = Self.id
        
        init(name: Parameter<String>) {
            self._name = name
        }
        
        func handle() throws -> EventLoopFuture<String> {
            print("-[\(Self.self) \(#function)] executed in pid \(getpid())")
            return RHI.invoke(
                RandomNumberGenerator.self,
                identifiedBy: .main,
                parameters: [.init(\.$upperBound, age)]
            )
            .map { randomNumber in
                "Hello \(name) of age \(age). Your random number in 0...\(age) is \(randomNumber)"
            }
        }
    }
    
    
    @PathParameter var name: String
    
    var content: some Component {
        Text("!!Hello World??! 👋")
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
//        Group("greet") {
//            TraditionalGreeter()
//                .serviceName("GreetService")
//                .rpcName("greetMe")
//                .response(EmojiMediator())
//        }
        Group("greet", $name) {
            Greeter(name: $name)
                .response(EmojiMediator(emojis: "😷", growth: 5))
        }
        Group("random", "int") {
            RandomNumberGenerator()
        }
    }
    
    var deploymentConfig: DeploymentConfig {
        DeploymentConfig(
            deploymentGroups: DeploymentGroupsConfig(
                defaultGrouping: .singleNode
//                groups: [
//                    .init(handlerIds: [RandomNumberGenerator.HandlerIdentifier.main]),
//                    .init(handlerIds: [Greeter.id])
//                ]
            )
        )
    }
}



extension DeploymentGroupsConfig.Group {
    init(handlerIds: [AnyHandlerIdentifier]) {
        self.init(handlerIds: handlerIds.map(\.rawValue))
    }
}


try TestWebService.main(deploymentProviders: [LocalhostRuntimeSupport.self, LambdaRuntime.self])
