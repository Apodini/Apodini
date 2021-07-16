//
// Created by Andreas Bauer on 16.07.21.
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
