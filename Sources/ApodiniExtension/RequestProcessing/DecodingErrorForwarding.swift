//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

/// Forwards errors that happen while retrieving parameters to the passed closure.
public struct DecodingErrorForwardingRequest: WithRequest {
    public let request: Request
    let forward: (Error) -> Void

    init(request: Request, forward: @escaping (Error) -> Void) {
        self.request = request
        self.forward = forward
    }

    public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element: Decodable, Element: Encodable {
        do {
            return try request.retrieveParameter(parameter)
        } catch {
            forward(error)
            throw error
        }
    }
}

extension ErrorForwarder {
    func forwardDecodingErrors(_ request: Request) -> DecodingErrorForwardingRequest {
        if let forward = forward {
            return DecodingErrorForwardingRequest(request: request, forward: forward)
        }
        return DecodingErrorForwardingRequest(request: request, forward: { _ in })
    }
}

extension Request {
    /// - Note: Best to use this just before evaluate() or subscribe() to catch all errors
    public func forwardDecodingErrors(with forwarder: ErrorForwarder) -> DecodingErrorForwardingRequest {
        forwarder.forwardDecodingErrors(self)
    }
}

extension AsyncSequence where Element: Request {
    /// - Note: Best to use this just before evaluate() or subscribe() to catch all errors
    public func forwardDecodingErrors(with forwarder: ErrorForwarder) -> AsyncMapSequence<Self, DecodingErrorForwardingRequest> {
        self.map { request in
            request.forwardDecodingErrors(with: forwarder)
        }
    }
}
