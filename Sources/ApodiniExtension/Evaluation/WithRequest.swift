//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import Logging

/// ``WithRequest`` implements Apodini's `Request` protocol by
/// forwarding the access to an underlying `Request`.
public protocol WithRequest: Request {
    /// The underlying `Request`.
    var request: Request { get }
}


public extension WithRequest {
    /// The default implementation of ``WithRequest`` for the ``description``
    /// forwards the call to the underlying `Request`.
    var description: String {
        request.description
    }

    /// The default implementation of ``WithRequest`` for the ``debugDescription``
    /// forwards the call to the underlying `Request`.
    var debugDescription: String {
        request.debugDescription
    }

    /// The default implementation of ``WithRequest`` for the ``eventLoop``
    /// forwards the call to the underlying `Request`.
    var eventLoop: EventLoop {
        request.eventLoop
    }

    /// The default implementation of ``WithRequest`` for the ``remoteAddress``
    /// forwards the call to the underlying `Request`.
    var remoteAddress: SocketAddress? {
        request.remoteAddress
    }
    
    /// The default implementation of ``WithRequest`` for ``information``
    /// forwards the call to the underlying `Request`.
    var information: InformationSet {
        request.information
    }
    
    var loggingMetadata: Logger.Metadata {
        request.loggingMetadata
    }
    
    private var defaultLoggingMetadata: Logger.Metadata {
        [
            /*
             /// Name of the endpoint (so the name of the handler class)
             "endpoint": .string("\(self.endpoint.description)"),
             /// Absolut path of the request
             "endpointAbsolutePath": .string("\(self.endpoint.absolutePath.asPathString())"),
             /// If size of the value a parameter is too big -> discard it and insert error message?
             // "@Parameter var name: String = World"
             "endpointParameters": .array(
                self.endpoint.parameters.map { parameter in
                    .string(parameter.description)
                }),
             */
             /// A textual description of the request, most detailed for the RESTExporter
             "request-desciption": .string(self.description),
             /// Set remote address
             "remoteAddress": .string("\(self.remoteAddress?.description ?? "")")
        ]
    }

    /// The default implementation of ``WithRequest`` for the ``retrieveParameter(_:)``
    /// function forwards the call to the underlying `Request`.
    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element {
        try request.retrieveParameter(parameter)
    }
}

public extension WithRequest {
    /// Unwraps this ``WithRequest`` or any of its (recursive) underlying
    /// `Request`s until it finds an instance that can be cast to `T` or returns
    /// `nil` if there is noting left to unwrap.
    func unwrapped<T: Request>(to type: T.Type = T.self) -> T? {
        if let typed = self as? T {
            return typed
        } else if let withRequest = self.request as? WithRequest {
            return withRequest.unwrapped()
        }
        return nil
    }
}
