//
//  UserHandler.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini


struct UserHandler: Handler {
    @Binding var userId: Int

    func handle() -> User {
        User(id: userId)
    }
}
