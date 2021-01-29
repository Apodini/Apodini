//
//  TestWebService.swift
//
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini


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
    }

    var configuration: Configuration {
        HTTP2Configuration()
            .certificate("/Users/moritzschull/Desktop/cert/cert.pem")
            .key("/Users/moritzschull/Desktop/cert/key.pem")
    }
}

try TestWebService.main()
