//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import _Concurrency

public extension AsyncSequence where Element: Request {
    /// This `AsyncSequence` maps each incoming `Request` to a ``CachingRequest``.
    func cache() -> AsyncMapSequence<Self, CachingRequest> {
        self.map { request in
            request.cache()
        }
    }
}

public extension Request {
    /// Wraps this `Request` into a ``CachingRequest``.
    func cache() -> CachingRequest {
        CachingRequest(self)
    }
}

/// A wrapper around an Apodini `Request` which caches all of the original request's
/// properties as well as the results of the ``retrieveParameter(_:)`` function.
public class CachingRequest: WithRequest {
    public let request: Request
    private var cache = [UUID: Any]()
    public private(set) lazy var description: String = request.description
    public private(set) lazy var debugDescription: String = request.debugDescription
    public private(set) lazy var eventLoop: EventLoop = request.eventLoop
    public private(set) lazy var remoteAddress: SocketAddress? = request.remoteAddress
    public private(set) lazy var information: InformationSet = request.information
    
    init(_ request: Request) {
        self.request = request
    }
    
    public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element: Decodable, Element: Encodable {
        // Note: we need the two-step if checking here since simply doing `if let value = cache[id] as? Element` would not
        // properly handle nested optionals.
        if let cached = cache[parameter.id], let typed = cached as? Element {
            return typed
        }
        let value = try request.retrieveParameter(parameter)
        cache[parameter.id] = value
        return value
    }
    
    /// This function allows for accessing the values stored in the cache.
    ///
    /// When ``peek(_:)`` is called it will never request a value from the
    /// underlying `Request`, instead it solely queries its cache and returns
    /// any value stored there.
    public func peek(_ parameter: UUID) -> Any? {
        cache[parameter]
    }
}
