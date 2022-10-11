//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation


extension AnyHTTPHeaderName {
    /// The `Authorization` HTTP header field
    public static let authorization = HTTPHeaderName<AuthorizationHTTPHeaderValue>("Authorization")
}


public enum AuthorizationHTTPHeaderValue: HTTPHeaderFieldValueCodable {
    case basic(credentials: String)
    /// See [RFC6750](https://datatracker.ietf.org/doc/html/rfc6750)
    case bearer(token: String)
    case other(type: String, credentials: String)


    public init?(httpHeaderFieldValue value: String) {
        guard let typeEndIdx = value.firstIndex(of: " ") else {
            return nil
        }
        let type = String(value[..<typeEndIdx])
        let rawCredentials = String(value[typeEndIdx...].dropFirst())
        switch type.lowercased() {
        case "basic":
            self = .basic(credentials: rawCredentials)
        case "bearer":
            self = .bearer(token: rawCredentials)
        default:
            self = .other(type: type, credentials: rawCredentials)
        }
    }

    public func encodeToHTTPHeaderFieldValue() -> String {
        switch self {
        case .basic(let credentials):
            return "Basic \(credentials)"
        case .bearer(let token):
            return "Bearer \(token)"
        case let .other(type, credentials):
            return "\(type) \(credentials)"
        }
    }
}
