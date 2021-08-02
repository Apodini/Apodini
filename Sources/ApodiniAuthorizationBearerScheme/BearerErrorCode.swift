//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIOHTTP1

/// Represents the Bearer error types as detailed in https://datatracker.ietf.org/doc/html/rfc6750#section-3.1
public enum BearerErrorCode: String {
    case invalidRequest = "invalid_request"
    case invalidToken = "invalid_token"
    case insufficientScope = "insufficient_scope"

    /// The HTTP Status code above error codes SHOULD return according to the RFC 6750
    var advisedStatusCode: HTTPResponseStatus {
        switch self {
        case .invalidRequest:
            return .badRequest
        case .invalidToken:
            return .unauthorized
        case .insufficientScope:
            return .forbidden
        }
    }
}
