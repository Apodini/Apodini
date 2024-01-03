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
    public let request: any Request
    let forwardClosure: (any Error) -> Void

    init(request: any Request, forward forwardClosure: @escaping (any Error) -> Void) {
        self.request = request
        self.forwardClosure = forwardClosure
    }

    public func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element {
        do {
            return try request.retrieveParameter(parameter)
        } catch {
            forwardClosure(error)
            throw error
        }
    }
}

extension ErrorForwarder {
    func forwardDecodingErrors(_ request: any Request) -> DecodingErrorForwardingRequest {
        DecodingErrorForwardingRequest(request: request, forward: forwardClosure ?? { _ in })
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
