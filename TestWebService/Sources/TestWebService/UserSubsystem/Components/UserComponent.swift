//
//  UserComponent.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini

struct UserComponent: Component {
    @PathParameter var userId: Int

    var content: some Component {
        Group {
            "user"
            $userId
        } content: {
            UserHandler(userId: $userId)
                .guard(LogGuard())
                .description("Returns `User` by id")
        }
    }
}
