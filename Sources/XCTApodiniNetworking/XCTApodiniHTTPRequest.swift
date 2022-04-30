//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

#if DEBUG || RELEASE_TESTING

import Foundation
import Apodini
@_exported import ApodiniNetworking


/// Testing request
public struct XCTHTTPRequest {
    /// HTTP version
    public let version: HTTPVersion
    /// HTTP method
    public let method: HTTPMethod
    /// URI
    public let url: URI
    /// headers
    public let headers: HTTPHeaders
    /// body
    public let body: ByteBuffer
    
    let file: StaticString
    let line: UInt
    
    /// Creates a testing request
    public init(
        version: HTTPVersion,
        method: HTTPMethod,
        url: URI,
        headers: HTTPHeaders = [:],
        body: ByteBuffer = .init(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.version = version
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.file = file
        self.line = line
    }
}


#endif // DEBUG || RELEASE_TESTING
