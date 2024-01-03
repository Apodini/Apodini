//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

struct BidirectionalGreeter: Handler {
    @Parameter(.http(.query)) var country: String?
    
    @Apodini.Environment(\.connection) var connection
    
    func handle() -> Apodini.Response<String> {
        switch connection.state {
        case .open:
            return .send("Hello, \(country ?? "World")!")
        case .end, .close:
            return .end
        }
    }
    
    var metadata: any AnyHandlerMetadata {
        Pattern(.bidirectionalStream)
    }
}
