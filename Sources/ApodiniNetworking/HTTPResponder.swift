//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import enum Apodini.CommunicationPattern


/// A `HTTPResponder` is a type that can respond to HTTP requests.
public protocol HTTPResponder {
    /// Handle a request received by the server.
    /// - Note: The responder is responsible for converting errors thrown when handling a request,
    ///         ideally by turning them into `HTTPResponse`s with an appropriate status code.
    func respond(to request: HTTPRequest) -> HTTPResponseConvertible
    
    /// Determines the expected communication pattern for a request.
    /// - returns: the expected communication pattern, or `nil` if this could not be determined
    /// - parameter request: The request for which the communication pattern should be determined. Note: this is an incomplete request object, which does not yet contain any body data.
    func expectedCommunicationPattern(for request: HTTPRequest) -> Apodini.CommunicationPattern?
}


extension HTTPResponder {
    /// :nodoc:
    public func expectedCommunicationPattern(for request: HTTPRequest) -> Apodini.CommunicationPattern? {
        nil
    }
}


public struct DefaultHTTPResponder: HTTPResponder {
    private let imp: (HTTPRequest) -> HTTPResponseConvertible
    
    public init(_ imp: @escaping (HTTPRequest) -> HTTPResponseConvertible) {
        self.imp = imp
    }
    
    public func respond(to request: HTTPRequest) -> HTTPResponseConvertible {
        imp(request)
    }
}
