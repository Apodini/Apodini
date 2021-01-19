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
            .response(EmojiMediator(emojis: "🎉"))
        
        // Bigger Subsystems:
        AuctionComponent()
        GreetComponent()
        RamdomComponent()
        SwiftComponent()
        UserComponent(userId: _userId)
    }
}

try TestWebService.main()
