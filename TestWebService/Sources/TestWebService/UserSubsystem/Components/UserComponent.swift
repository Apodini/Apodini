//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
                .identified(by: "getUserById")
            Group {
                "post"
                    .relationship(name: "posts")
                $postId
            } content: {
                PostHandler(userId: $userId, postId: $postId)
                    .identified(by: "getPost")
                    .guard(LogGuard())
            }
        }
        Group("authenticated") {
            AuthenticatedUserHandler()
                .identified(by: "getAuthenticatedUser")
                .guard(LogGuard())
                .description("Returns the currently authenticated `User`")
        }
    }
}
