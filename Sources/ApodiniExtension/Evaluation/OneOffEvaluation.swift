//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniUtils
import Foundation
import NIO

/// A wrapper which contains the input-output pair of a `Delegate`'s evaluation.
public struct ResponseWithRequest<C: Encodable>: WithRequest {
    public let response: Response<C>
    public let request: Request
}

public extension Request {
    /// Evaluates this `Request` on the given `handler` with the given `state` and returns the
    /// resulting `Response` future.
    func evaluate<H: Handler>(on handler: Delegate<H>, _ state: ConnectionState = .end) async throws -> Response<H.Response.Content> {
        try await handler.evaluate(using: self, with: state)
    }
    
    /// Evaluates this `Request` on the given `handler` with the given `state` and returns the
    /// resulting ``ResponseWithRequest``
    func evaluate<H: Handler>(on handler: Delegate<H>,
                              _ state: ConnectionState = .end) async throws -> ResponseWithRequest<H.Response.Content> {
        let response: Response<H.Response.Content> = try await self.evaluate(on: handler, state)
        return ResponseWithRequest(response: response, request: self)
    }
    
    /// Evaluates this `Request` on the given `handler` with the given `state` and returns the
    /// resulting `Response` future.
    func evaluate<H: Handler>(on handler: Delegate<H>, _ state: ConnectionState = .end) -> EventLoopFuture<Response<H.Response.Content>> {
        handler.evaluate(using: self, with: state)
    }
    
    /// Evaluates this `Request` on the given `handler` with the given `state` and returns the
    /// resulting ``ResponseWithRequest``
    func evaluate<H: Handler>(on handler: Delegate<H>,
                              _ state: ConnectionState = .end) -> EventLoopFuture<ResponseWithRequest<H.Response.Content>> {
        self.evaluate(on: handler, state).map { (response: Response<H.Response.Content>) in
            ResponseWithRequest(response: response, request: self)
        }
    }
}

internal extension Delegate where D: Handler {
    func evaluate(using request: Request, with state: ConnectionState = .end) async throws -> D.Response {
        try await _Internal.evaluate(delegate: self, using: request, with: state)
    }
    
    func evaluate(using request: Request, with state: ConnectionState = .end) -> EventLoopFuture<Response<D.Response.Content>> {
        let promise = request.eventLoop.makePromise(of: Response<D.Response.Content>.self)
        
        promise.completeWithTask {
            try await self.evaluate(using: request, with: state)
        }
        
        return promise.futureResult
    }
    
    func evaluate(using request: Request, with state: ConnectionState = .end) async throws -> Response<D.Response.Content> {
        let result: D.Response = try await self.evaluate(using: request, with: state)
        return try await result.transformToResponse(on: request.eventLoop).get()
    }
    
    func evaluate(_ trigger: TriggerEvent,
                  using request: Request,
                  with state: ConnectionState = .end) -> EventLoopFuture<Response<D.Response.Content>> {
        let promise = request.eventLoop.makePromise(of: Response<D.Response.Content>.self)
        
        promise.completeWithTask {
            try await self.evaluate(trigger, using: request, with: state)
        }
        
        return promise.futureResult
    }
    
    func evaluate(_ trigger: TriggerEvent,
                  using request: Request,
                  with state: ConnectionState = .end) async throws -> Response<D.Response.Content> {
        self.setChanged(to: true, reason: trigger)
        
        guard !trigger.cancelled else {
            self.setChanged(to: false, reason: trigger)
            return .nothing
        }
        
        do {
            let response: Response<D.Response.Content> = try await self.evaluate(using: request, with: state)
            self.setChanged(to: false, reason: trigger)
            return response
        } catch {
            self.setChanged(to: false, reason: trigger)
            throw error
        }
    }
}
