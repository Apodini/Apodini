//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIOHTTP1

public struct DATAFrameRequest<T: Encodable>: Encodable {
    var query: T
    
    public init(_ query: T) {
        self.query = query
    }
}

/// Basic HTTP request header fields
public struct BasicHTTPHeaderFields {
    var method: HTTPMethod
    var url: String
    var host: String
    
    /// Create basic HTTP header fields
    public init(_ method: HTTPMethod, _ url: String, _ host: String) {
        self.method = method
        self.url = url
        self.host = host
    }
}
