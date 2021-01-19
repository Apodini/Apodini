//
//  main.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-18.
//

import Foundation
import Apodini
//import Vapor
//import AWSLambdaRuntime
//import AWSLambdaEvents
import NIO
//import VaporAWSLambdaRuntime
import DeploymentTargetAWSLambdaRuntime


//print("OWOOOOOO")
//
//struct SimpleConfiguration: Apodini.Configuration {
//    private let action: (Apodini.Application) -> Void
//
//    init(_ action: @escaping (Apodini.Application) -> Void) {
//        self.action = action
//    }
//
//    func configure(_ app: Apodini.Application) {
//        action(app)
//    }
//}




struct WebService: Apodini.WebService {
    struct RandomNumberGenerator: InvocableHandler {
        class HandlerIdentifier: ScopedHandlerIdentifier<RandomNumberGenerator> {
            static let main = HandlerIdentifier("main")
        }
        let handlerId = HandlerIdentifier.main
        
        @Parameter var lowerBound: Int = 0
        @Parameter var upperBound: Int = .max
        
        func handle() throws -> Int {
            guard lowerBound <= upperBound else {
                throw NSError(domain: "TestWebServiceAWS", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid range"])
            }
            return Int.random(in: lowerBound...upperBound)
        }
        
    }
    struct Greeter: Handler {
        private var RHI = RemoteHandlerInvocationManager()
        
        @Parameter(.http(.path)) var name: String
        @Parameter(.http(.query)) var age: Int
        
        func handle() -> EventLoopFuture<String> {
            RHI.invoke(
                RandomNumberGenerator.self,
                identifiedBy: .main,
                parameters: [.init(\.$upperBound, age)]
            )
            .map { "Hello, \(name)! Your random number is \(-$0)." }
        }
    }
    
    var content: some Component {
        Text("hello")
        Group("greet") {
            Greeter()
        }
        Group("rand") {
            RandomNumberGenerator()
        }
    }
    
//    var configuration: Configuration {
//        SimpleConfiguration { app in
//            app.vapor.app.servers.use(.lambda)
//        }
//    }
}


try WebService.main(deploymentProviders: [LambdaRuntime.self])



//struct IncomingRequestHandler: EventLoopLambdaHandler {
//    typealias In = APIGateway.V2.Request
//    typealias Out = APIGateway.V2.Response
//
//    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
//        print(#function, context, event)
//        //context.logger.notice("\(#function) \(context) \(event)")
//        let response: Out = .init(
//            statusCode: .imATeapot,
//            headers: ["ugh": "test"],
//            multiValueHeaders: nil,
//            //body: "owoo\n\n[context]\n\(String(describing: context))\n\n",
//            body: """
//            owoooo
//
//            [context]
//            \(String(reflecting: context))
//
//            [event]
//            \(String(reflecting: event))
//            """,
//            isBase64Encoded: false,
//            cookies: nil
//        )
//        return context.eventLoop.makeSucceededFuture(response)
//    }
//}
//
//Lambda.run(IncomingRequestHandler())
