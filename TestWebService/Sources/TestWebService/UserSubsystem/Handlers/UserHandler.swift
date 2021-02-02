//
//  UserHandler.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Foundation
import Apodini


struct UserHandler: Handler {
    @Parameter var userId: UUID

    func handle() -> User {
        User(id: userId)
    }
}
