//
//  UserComponent.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Foundation
import Apodini


struct UserComponent: Component {
    @PathParameter(identifying: User.self) var userId: Int
    @PathParameter(identifying: Post.self) var postId: UUID

    let greeterRelationship: Relationship
    
    var content: some Component {
        Group("user", $userId) {
            UserHandler(userId: $userId)
                .guard(LogGuard())
                .description("Returns `User` by id")
                .relationship(to: greeterRelationship)
            Group {
                "post"
                    .relationship(name: "posts")
                $postId
            } content: {
                PostHandler(postId: $postId)
                    .guard(LogGuard())
            }
        }
        Group("authenticated") {
            AuthenticatedUserHandler()
                .guard(LogGuard())
                .description("Returns the currently authenticated `User`")
        }
    }
}
