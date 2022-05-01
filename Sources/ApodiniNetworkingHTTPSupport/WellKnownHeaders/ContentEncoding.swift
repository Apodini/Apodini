//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation


extension AnyHTTPHeaderName {
    /// The `Content-Encoding` HTTP header field
    public static let contentEncoding = HTTPHeaderName<[ContentEncodingHTTPHeaderValue]>("Content-Encoding")
}


public enum ContentEncodingHTTPHeaderValue: String, HTTPHeaderFieldValueCodable {
    case gzip
    case compress
    case deflate
    case br // swiftlint:disable:this identifier_name
    
    public init?(httpHeaderFieldValue value: String) {
        self.init(rawValue: value)
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        self.rawValue
    }
}
