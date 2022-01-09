//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

/// A `Request` which forwards errors that occur when retrieving
/// parameters from another `Request`.
///
/// - Note: Thrown `Error`s will be forwarded transparently so they can be
///         handled properly afterwards.
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
    /// Wraps each incoming `Request` into a ``DecodingErrorForwardingRequest`` using
    /// the given `ErrorForwarder`.
    ///
    /// - Note: It's best to use this wrapper just before `evaluate(on:)` to
    ///         catch errors in all decoding steps.
    public func forwardDecodingErrors(with forwarder: ErrorForwarder) -> DecodingErrorForwardingRequest {
        forwarder.forwardDecodingErrors(self)
    }
}

extension AsyncSequence where Element: Request {
    /// Wraps each incoming `Request` into a ``DecodingErrorForwardingRequest`` using
    /// the given `ErrorForwarder`.
    ///
    /// - Note: It's best to use this wrapper just before
    ///         `evaluate(on:)` / `subscribe(to:)` to catch errors in all
    ///         decoding steps.
    public func forwardDecodingErrors(with forwarder: ErrorForwarder) -> AsyncMapSequence<Self, DecodingErrorForwardingRequest> {
        self.map { request in
            request.forwardDecodingErrors(with: forwarder)
        }
    }
}
