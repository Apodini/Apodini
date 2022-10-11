//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation


extension AnyHTTPHeaderName {
    /// The `Access-Control-Allow-Origin` header field
    public static let accessControlAllowOrigin = HTTPHeaderName<AccessControlAllowOriginHeaderValue>("Access-Control-Allow-Origin")
}


public enum AccessControlAllowOriginHeaderValue: HTTPHeaderFieldValueCodable {
    case wildcard
    case origin(String)
    case null

    public init?(httpHeaderFieldValue value: String) {
        switch value {
        case "*":
            self = .wildcard
        case "null":
            self = .null
        default:
            self = .origin(value)
        }
    }

    public func encodeToHTTPHeaderFieldValue() -> String {
        switch self {
        case .wildcard:
            return "*"
        case .origin(let origin):
            return origin
        case .null:
            return "null"
        }
    }
}
