//
//  ConnectionContext.swift
//  
//
//  Created by Max Obermeier on 31.12.20.
//

import Foundation
@_implementationOnly import Vapor
@_implementationOnly import Fluent


/// `ConnectionContext` holds the internal state of an endpoint for one connection
/// in a format suitable for a specific `InterfaceExporter`.
protocol ConnectionContext {
    associatedtype I: InterfaceExporter
    
    mutating func handle(
        request exporterRequest: I.ExporterRequest,
        eventLoop: EventLoop
    ) -> EventLoopFuture<Action<AnyEncodable>>
}
struct AnyConnectionContext<I: InterfaceExporter>: ConnectionContext {
    private var handleFunc: (
        _: I.ExporterRequest,
        _: EventLoop
    ) -> EventLoopFuture<Action<AnyEncodable>>
    
    init<C: ConnectionContext>(from context: C) where C.I == I {
        var context = context
        self.handleFunc = { request, eventLoop in
            context.handle(request: request, eventLoop: eventLoop)
        }
    }
    
    func handle(request exporterRequest: I.ExporterRequest, eventLoop: EventLoop) -> EventLoopFuture<Action<AnyEncodable>> {
        self.handleFunc(exporterRequest, eventLoop)
    }
}

extension ConnectionContext {
    func eraseToAnyConnectionContext() -> AnyConnectionContext<I> {
        AnyConnectionContext(from: self)
    }
}

class InternalConnectionContext<H: Handler, I: InterfaceExporter>: ConnectionContext {
    
    private let exporter: I
    
    private var validator: AnyValidator<I, EventLoop, ValidatedRequest<I, H>>
    
    private let endpoint: Endpoint<H>
    
    private var requestHandler: InternalEndpointRequestHandler<I, H> {
        InternalEndpointRequestHandler(endpoint: self.endpoint, exporter: self.exporter)
    }
    
    init(for exporter: I, on endpoint: Endpoint<H>) {
        self.exporter = exporter
        
        self.endpoint = endpoint
        
        self.validator = endpoint.validator(for: exporter)
    }
    
    func handle(
        request exporterRequest: I.ExporterRequest,
                eventLoop: EventLoop
            ) -> EventLoopFuture<Action<AnyEncodable>> {
        
        
        do {
            let validatedRequest = try validator.validate(exporterRequest, with: eventLoop)
            
            return self.requestHandler(request: validatedRequest)
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}

extension ConnectionContext where I.ExporterRequest: WithEventLoop {
    mutating func handle(request: I.ExporterRequest) -> EventLoopFuture<Action<AnyEncodable>> {
        handle(request: request, eventLoop: request.eventLoop)
    }
}
