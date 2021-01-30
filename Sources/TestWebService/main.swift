//
//  TestWebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini
import ApodiniDeployBuildSupport
import DeploymentTargetAWSLambdaCommon


struct TestHandler: Handler {
    func handle() throws -> String {
        "owoooo"
    }
    
    static var deploymentOptions: HandlerDeploymentOptions {
        HandlerDeploymentOptions(
            .init(key: LambdaHandlerOption.memorySizeInMB, value: 500)
        )
    }
}


struct TestWebService: Apodini.WebService {
    @PathParameter var userId: Int
    
    var content: some Component {
        // Hello World! 👋
        Text("Hello World! 👋")
            .response(EmojiTransformer(emojis: "🎉"))
        
        // Bigger Subsystems:
        AuctionComponent()
        GreetComponent()
        RamdomComponent()
        SwiftComponent()
        UserComponent(userId: _userId)
        
        Group("xxx") {
            TestHandler()
        }
    }
}

try TestWebService.main()
