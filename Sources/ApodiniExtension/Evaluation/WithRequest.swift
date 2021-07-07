//
//  WithRequest.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Apodini

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
    var information: Set<AnyInformation> {
        request.information
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
