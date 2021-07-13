//
//  Caching.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import Apodini
import OpenCombine
import _Concurrency

@available(macOS 12.0, *)
public extension AsyncSequence where Element: Request {
    func cache() -> AsyncMapSequence<Self, CachingRequest> {
        self.map { request in
            request.cache()
        }
    }
}

public extension Publisher where Output: Request {
    /// This `Publisher` maps each incoming `Request` into a ``CachingRequest``.
    func cache() -> OpenCombine.Publishers.Map<Self, CachingRequest> {
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
    public var request: Request
    
    private var cache = [UUID: Any]()
    
    init(_ request: Request) {
        self.request = request
    }
    
    public lazy var description: String = request.description

    public lazy var debugDescription: String = request.debugDescription

    public lazy var eventLoop: EventLoop = request.eventLoop

    public lazy var remoteAddress: SocketAddress? = request.remoteAddress
    
    public lazy var information: InformationSet = request.information
    
    public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element: Decodable, Element: Encodable {
        if let cached = cache[parameter.id] {
            if let typed = cached as? Element {
                return typed
            }
        }
        
        let value = try request.retrieveParameter(parameter)
        cache[parameter.id] = value
        return value
    }
    
    /// This function allows for accessing the values stored in the cache.
    ///
    /// When ``peak(_:)`` is called it will never request a value from the
    /// underlying `Request`, instead it solely queries its cache and returns
    /// any value stored there.
    public func peak(_ parameter: UUID) -> Any? {
        cache[parameter]
    }
}
