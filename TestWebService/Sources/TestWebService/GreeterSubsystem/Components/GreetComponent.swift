//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniGRPC


struct GreetComponent: Component {
    let greeterRelationship: Relationship

    var content: some Component {
        Group("greet") {
            TraditionalGreeter()
                .gRPCServiceName("GreetService")
                .gRPCMethodName("GreetMe")
                .response(EmojiTransformer())
                .destination(of: greeterRelationship)
                .identified(by: "greetMe")
        }
    }
}
