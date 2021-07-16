//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniHTTPProtocol
import Vapor

// MARK: AbortError

extension ApodiniError: AbortError {
    public var status: HTTPResponseStatus {
        self.option(for: .httpResponseStatus)
    }
    
    public var reason: String {
        self.standardMessage
    }
    
    public var headers: HTTPHeaders {
        HTTPHeaders(information)
    }
}
