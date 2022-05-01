//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation


extension AnyHTTPHeaderName {
    /// The `Transfer-Encoding` HTTP header field
    public static let transferEncoding = HTTPHeaderName<[TransferEncodingHTTPHeaderValue]>("Transfer-Encoding")
}


public enum TransferEncodingHTTPHeaderValue: String, HTTPHeaderFieldValueCodable {
    case chunked
    case compress
    case deflate
    case gzip
    
    public init?(httpHeaderFieldValue value: String) {
        self.init(rawValue: value)
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        self.rawValue
    }
}
