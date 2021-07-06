//
//  OneOffEvaluation.swift
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

public extension Request {
    /// Evaluates this `Request` on the given `handler` with the given `state` and returns the
    /// resulting `Response` future.
    func evaluate<H: Handler>(on handler: inout Delegate<H>, _ state: ConnectionState = .end)
        -> EventLoopFuture<Response<H.Response.Content>> {
        _Internal.prepareIfNotReady(&handler)
        return handler.evaluate(using: self, with: state)
    }
    
    /// Evaluates this `Request` on the given `handler` with the given `state` and returns the
    /// resulting ``ResponseWithRequest``
    func evaluate<H: Handler>(on handler: inout Delegate<H>, _ state: ConnectionState = .end)
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
