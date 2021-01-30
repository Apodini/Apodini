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
import DeploymentTargetAWSLambdaCommon
import DeploymentTargetAWSLambdaRuntime


struct TestHandler: Handler {
    func handle() throws -> String {
        "owoooo"
    }
    
    static var deploymentOptions: HandlerDeploymentOptions {
        HandlerDeploymentOptions(
            .init(key: LambdaHandlerOption.memorySize, value: 256)
        )
    }
}



struct RandomNumberGenerator: InvocableHandler {
    class HandlerIdentifier: ScopedHandlerIdentifier<RandomNumberGenerator> {
        static let main = HandlerIdentifier("main")
    }
    
    let handlerId = HandlerIdentifier.main
    @Parameter var lowerBound: Int = 0
    @Parameter var upperBound: Int = .max
    
    func handle() -> Int {
        print("handler \(Self.self) in pid \(getpid())")
        guard lowerBound <= upperBound else {
            return 0
        }
        return Int.random(in: lowerBound...upperBound)
    }
}



struct NewGreeter: Handler {
    private let RHI = RemoteHandlerInvocationManager()
    
    @Parameter(.http(.path)) var name: String
    @Parameter var age: Int
    
    func handle() -> EventLoopFuture<String> {
        print("handler \(Self.self) in pid \(getpid())")
        return RHI.invoke(
            RandomNumberGenerator.self,
            identifiedBy: .main,
            parameters: [
                .init(\.$lowerBound, age),
                .init(\.$upperBound, 2*age),
            ]
        )
        .map { number -> String in
            return "Hello, \(name)!. Your random number in age ... 2*age is: \(number)"
        }
    }
}



struct TestWebService: Apodini.WebService {
    @PathParameter var userId: Int
    
    var content: some Component {
        // Hello World! 👋
        Text("Hello World! 👋")
            .response(EmojiTransformer(emojis: "🎉"))
        
        // Bigger Subsystems:
        //AuctionComponent()
        //GreetComponent()
        //RamdomComponent()
        //SwiftComponent()
        //UserComponent(userId: _userId)
        
        Group("greet") { NewGreeter() }
        Group("rand") { RandomNumberGenerator() }
        
        Group("xxx") {
            TestHandler()
        }
    }
    
    var configuration: Configuration {
        OpenAPIConfiguration(
            outputFormat: .json,
            outputEndpoint: "oas",
            swaggerUiEndpoint: "oas-ui",
            title: "The great TestWebService - presented by Apodini"
        )
    }
}

try TestWebService.main(deploymentProviders: [
    LocalhostRuntimeSupport.self, LambdaRuntime.self
])
