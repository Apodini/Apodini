//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation


extension AnyHTTPHeaderName {
    /// The `Upgrade` HTTP header field
    public static let upgrade = HTTPHeaderName<[HTTPUpgradeHeaderValue]>("Upgrade")
}


public enum HTTPUpgradeHeaderValue: HTTPHeaderFieldValueCodable {
    case http2
    case webSocket
    case other(String)
    
    public init?(httpHeaderFieldValue value: String) {
        switch value {
        case "HTTP/2.0", "HTTP/2":
            self = .http2
        case "websocket":
            self = .webSocket
        default:
            self = .other(value)
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        switch self {
        case .http2:
            return "HTTP/2.0"
        case .webSocket:
            return "websocket"
        case .other(let value):
            return value
        }
    }
}
