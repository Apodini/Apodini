//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini


struct SwiftComponent: Component {
    var content: some Component {
        Group("swift") {
            Text("Hello Swift! 💻")
                .response(EmojiTransformer())
                .guard(LogGuard())
            Group("5", "3") {
                Text("Hello Swift 5! 💻")
            }
        }.guard(LogGuard("Someone is accessing Swift 😎!!"))
    }
}
