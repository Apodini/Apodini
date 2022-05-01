//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation


extension AnyHTTPHeaderName {
    /// The `ETag` HTTP header field
    public static let eTag = HTTPHeaderName<ETagHTTPHeaderValue>("ETag")
}


public enum ETagHTTPHeaderValue: HTTPHeaderFieldValueCodable {
    case weak(String)
    case strong(String)
    
    public init?(httpHeaderFieldValue value: String) {
        if value.hasPrefix("W/") {
            self = .weak(value)
        } else {
            self = .strong(value)
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        switch self {
        case .weak(let value), .strong(let value):
            return value
        }
    }
}
