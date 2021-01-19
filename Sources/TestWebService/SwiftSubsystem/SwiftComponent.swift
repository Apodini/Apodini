//
//  SwiftComponent.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini


struct SwiftComponent: Component {
    var content: some Component {
        Group("swift") {
            Text("Hello Swift! 💻")
                .response(EmojiMediator())
                .guard(LogGuard())
            Group("5", "3") {
                Text("Hello Swift 5! 💻")
            }
        }.guard(LogGuard("Someone is accessing Swift 😎!!"))
    }
}
