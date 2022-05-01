//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation
import NIOHTTP1


public extension AnyHTTPHeaderName {
    /// The HTTP/2 `:method` pseudo header field
    static let methodPseudoHeader = HTTPHeaderName<HTTPMethod>(":method")
    /// The HTTP/2 `:path` pseudo header field
    static let pathPseudoHeader = HTTPHeaderName<String>(":path")
    /// The HTTP/2 `:status` pseudo header field
    static let statusPseudoHeader = HTTPHeaderName<HTTPResponseStatus>(":status")
    /// The HTTP/2 `:authority` pseudo header field
    static let authorityPseudoHeader = HTTPHeaderName<String>(":authority")
    /// The HTTP/2 `:scheme` pseudo header field
    static let schemePseudoHeader = HTTPHeaderName<HTTPSchemePseudoHeaderValue>(":scheme")
}


extension HTTPMethod: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        self.init(rawValue: value)
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        self.rawValue
    }
}


extension HTTPResponseStatus: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        if let intValue = Int(value) {
            self.init(statusCode: intValue)
        } else {
            return nil
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        String(code)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(reasonPhrase)
    }
}


public enum HTTPSchemePseudoHeaderValue: HTTPHeaderFieldValueCodable {
    case http
    case https
    case other(String)
    
    public init?(httpHeaderFieldValue value: String) {
        switch value.lowercased() {
        case "http":
            self = .http
        case "https":
            self = .https
        default:
            self = .other(value)
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        switch self {
        case .http:
            return "http"
        case .https:
            return "https"
        case .other(let value):
            return value
        }
    }
}
