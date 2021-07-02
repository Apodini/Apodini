//
//  Evaluation.swift
//  
//
//  Created by Max Obermeier on 22.06.21.
//

import Apodini
import ApodiniUtils
import Foundation

/// A wrapper which contains the input-output pair of a `Delegate`'s evaluation.
public struct ResponseWithRequest<C: Encodable>: WithRequest {
    public let response: Response<C>
    public let request: Request
}

extension Request {
    /// Evaluates this `Request` on the given `handler` with the given `state` and returns the
    /// resulting `Response` future.
    public func evaluate<H: Handler>(on handler: inout Delegate<H>, _ state: ConnectionState = .end)
        -> EventLoopFuture<Response<H.Response.Content>> {
        _Internal.prepareIfNotReady(&handler)
        return handler.evaluate(using: self, with: state)
    }
    
    /// Evaluates this `Request` on the given `handler` with the given `state` and returns the
    /// resulting ``ResponseWithRequest``
    public func evaluate<H: Handler>(on handler: inout Delegate<H>, _ state: ConnectionState = .end)
        -> EventLoopFuture<ResponseWithRequest<H.Response.Content>> {
        self.evaluate(on: &handler, state).map { (response: Response<H.Response.Content>) in
            ResponseWithRequest(response: response, request: self)
        }
    }
}

internal extension Delegate where D: Handler {
    func evaluate(using request: Request, with state: ConnectionState = .end) throws -> D.Response {
        try _Internal.evaluate(delegate: self, using: request, with: state)
    }
    
    func evaluate(using request: Request, with state: ConnectionState = .end)
        -> EventLoopFuture<Response<D.Response.Content>> {
        request.eventLoop.makeSucceededVoidFuture().flatMap {
            do {
                let result: D.Response = try self.evaluate(using: request, with: state)
                return result.transformToResponse(on: request.eventLoop)
            } catch {
                return request.eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    func evaluate(_ trigger: TriggerEvent, using request: Request, with state: ConnectionState = .end)
        -> EventLoopFuture<Response<D.Response.Content>> {
        self.setChanged(to: true, reason: trigger)
        
        guard !trigger.cancelled else {
            self.setChanged(to: false, reason: trigger)
            return request.eventLoop.makeSucceededFuture(.nothing)
        }
        
        return self.evaluate(using: request, with: state).always { _ in
            self.setChanged(to: false, reason: trigger)
        }
    }
}


// MARK: WithRequest

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
    /// Unwrapps this ``WithRequest`` or any of its (recursive) underlying
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
