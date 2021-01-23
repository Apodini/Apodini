//
// Created by Andreas Bauer on 22.01.21.
//

import Foundation
import Apodini

struct PostHandler: Handler {
    @Parameter var postId: UUID

    func handle() -> Post {
        Post(id: postId, title: "Example Title")
    }
}
