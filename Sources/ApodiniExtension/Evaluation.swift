//
//  Evaluation.swift
//  
//
//  Created by Max Obermeier on 22.06.21.
//

import Apodini
import ApodiniUtils
import Foundation

public struct ResponseWithRequest<C: Encodable>: WithRequest {
    public let response: Response<C>
    public let request: Request
}

extension Request {
    public func evaluate<H: Handler>(on handler: H) -> EventLoopFuture<Response<H.Response.Content>> {
        let delegate = Delegate.standaloneInstance(of: handler)
        return delegate.evaluate(using: self)
    }
    
    public func evaluate<H: Handler>(on handler: H) -> EventLoopFuture<ResponseWithRequest<H.Response.Content>> {
        self.evaluate(on: handler).map { (response: Response<H.Response.Content>) in
            ResponseWithRequest(response: response, request: self)
        }
    }
}

internal extension Delegate where D: Handler {
    static func standaloneInstance(of delegate: D) -> Delegate<D> {
        return IE.standaloneDelegate(delegate)
    }
    
    func evaluate(using request: Request, with state: ConnectionState = .end) throws -> D.Response {
        return try IE.evaluate(delegate: self, using: request, with: state)
    }
    
    func evaluate(using request: Request, with state: ConnectionState = .end) -> EventLoopFuture<Response<D.Response.Content>> {
        request.eventLoop.makeSucceededVoidFuture().flatMap {
            do {
                let result: D.Response = try self.evaluate(using: request, with: state)
                return result.transformToResponse(on: request.eventLoop)
            } catch {
                return request.eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    func evaluate(_ trigger: TriggerEvent, using request: Request, with state: ConnectionState = .end) -> EventLoopFuture<Response<D.Response.Content>> {
        guard !trigger.cancelled else {
            return request.eventLoop.makeSucceededFuture(.nothing)
        }
        
        self.setChanged(to: true, reason: trigger)
        return self.evaluate(using: request, with: state).always { _ in
            self.setChanged(to: false, reason: trigger)
        }
    }
}


// MARK: WithRequest

public protocol WithRequest: Request {
    var request: Request { get }
}


public extension WithRequest {
    var description: String {
        request.description
    }

    var debugDescription: String {
        request.debugDescription
    }

    var eventLoop: EventLoop {
        request.eventLoop
    }

    var remoteAddress: SocketAddress? {
        request.remoteAddress
    }
    
    var information: Set<AnyInformation> {
        request.information
    }

    func retrieveParameter<Element: Codable>(_ parameter: Parameter<Element>) throws -> Element {
        try request.retrieveParameter(parameter)
    }
}

public extension WithRequest {
    func unwrapped<T: Request>(to type: T.Type = T.self) -> T? {
        if let typed = self as? T {
            return typed
        } else if let withRequest = self.request as? WithRequest {
            return withRequest.unwrapped()
        }
        return nil
    }
}
