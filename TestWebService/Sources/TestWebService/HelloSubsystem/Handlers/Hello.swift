//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

struct Hello: Handler {
    @Environment(\.connection) var connection: Connection
//    @Parameter var name: String
    
    func handle() -> Apodini.Response<String> {
        switch connection.state {
        case .open:
            print("Handler: sending hi")
            return .send("Hi")
        case .end:
            print("Handler: sending final hi")
            return .final("Hi")
        default:
            print("Handler: sending final")
            return .final()
        }
    }
    
    var metadata: AnyHandlerMetadata {
        Pattern(.bidirectionalStream)
        Operation(.create)
    }
}
