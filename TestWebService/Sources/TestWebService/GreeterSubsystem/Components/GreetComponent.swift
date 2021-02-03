//
//  GreetComponent.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini


struct GreetComponent: Component {
    var content: some Component {
        Group("greet") {
            TraditionalGreeter()
                .serviceName("GreetService")
                .rpcName("greetMe")
                .response(EmojiTransformer())
                .serviceType(.unary)
        }
    }
}
