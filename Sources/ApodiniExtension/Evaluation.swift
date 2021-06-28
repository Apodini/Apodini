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

public struct EmptyRequest: Request {
    public var description: String {
        "EmptyRequest(eventLoop: \(eventLoop), remoteAddress: \(remoteAddress?.description ?? "nil"), information: \(information))"
    }
    
    public var debugDescription: String {
        self.description
    }
    
    public let eventLoop: EventLoop
    
    public var remoteAddress: SocketAddress?
    
    public var information: Set<AnyInformation>
    
    public init(eventLoop: EventLoop, remoteAddress: SocketAddress? = nil, information: Set<AnyInformation> = []) {
        self.eventLoop = eventLoop
        self.remoteAddress = remoteAddress
        self.information = information
    }
    
    public func retrieveParameter<Element>(_ parameter: Parameter<Element>) throws -> Element where Element : Decodable, Element : Encodable {
        throw DecodingError.valueNotFound(Element.self, DecodingError.Context(codingPath: [], debugDescription: "Tried to retrieve parameter from empty request.", underlyingError: nil))
    }
}

extension Request {
    public func evaluate<H: Handler>(on handler: inout Delegate<H>, _ state: ConnectionState = .end) -> EventLoopFuture<Response<H.Response.Content>> {
        _Internal.prepareIfNotReady(&handler)
        return handler.evaluate(using: self, with: state)
    }
    
    public func evaluate<H: Handler>(on handler: inout Delegate<H>, _ state: ConnectionState = .end) -> EventLoopFuture<ResponseWithRequest<H.Response.Content>> {
        self.evaluate(on: &handler, state).map { (response: Response<H.Response.Content>) in
            ResponseWithRequest(response: response, request: self)
        }
    }
}

internal extension Delegate where D: Handler {
    
    func evaluate(using request: Request, with state: ConnectionState = .end) throws -> D.Response {
        return try _Internal.evaluate(delegate: self, using: request, with: state)
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
