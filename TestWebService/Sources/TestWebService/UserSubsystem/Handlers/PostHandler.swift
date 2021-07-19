//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
import Apodini

struct PostHandler: Handler {
    @Binding var userId: Int
    @Binding var postId: UUID

    func handle() -> Post {
        Post(id: postId, title: "Example Title")
    }
}
