//
//  TestWebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Foundation
import Apodini


struct TestWebService: Apodini.WebService {
    @PathParameter var userId: UUID
    
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

try TestWebService.main()
