//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation


extension AnyHTTPHeaderName {
    /// The `Connection` HTTP header field
    public static let connection = HTTPHeaderName<[HTTPConnectionHeaderValue]>("Connection")
}


public enum HTTPConnectionHeaderValue: HTTPHeaderFieldValueCodable {
    case close
    case keepAlive
    case upgrade
    case other(String)

    public static func other(_ headerName: AnyHTTPHeaderName) -> Self {
        Self(httpHeaderFieldValue: headerName.rawValue)!
    }

    public init?(httpHeaderFieldValue value: String) {
        switch value.lowercased() {
        case "close":
            self = .close
        case "keep-alive":
            self = .keepAlive
        case "upgrade":
            self = .upgrade
        default:
            self = .other(value)
        }
    }

    public func encodeToHTTPHeaderFieldValue() -> String {
        switch self {
        case .close:
            return "close"
        case .keepAlive:
            return "Keep-Alive"
        case .upgrade:
            return "Upgrade"
        case .other(let value):
            return value
        }
    }
}
