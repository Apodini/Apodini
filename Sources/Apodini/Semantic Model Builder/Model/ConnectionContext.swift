//
//  ConnectionContext.swift
//  
//
//  Created by Max Obermeier on 31.12.20.
//

import Foundation
@_implementationOnly import Vapor
@_implementationOnly import Fluent

/// An object that can merge itself and a `new` element
/// of same type.
protocol Reducible {
    func reduce(to new: Self) -> Self
}

extension Reducible {
    func reduce(to new: Self) -> Self {
        new
    }
}

/// `ConnectionContext` holds the internal state of an endpoint for one connection
/// in a format suitable for a specific `InterfaceExporter`.
protocol ConnectionContext {
    associatedtype Exporter: InterfaceExporter
    
    mutating func handle(
        request exporterRequest: Exporter.ExporterRequest,
        eventLoop: EventLoop,
        final: Bool
    ) -> EventLoopFuture<Response<AnyEncodable>>
}

extension ConnectionContext {
    mutating func handle(
        request exporterRequest: Exporter.ExporterRequest,
        eventLoop: EventLoop
    ) -> EventLoopFuture<Response<AnyEncodable>> {
        self.handle(request: exporterRequest, eventLoop: eventLoop, final: true)
    }
}

struct AnyConnectionContext<I: InterfaceExporter>: ConnectionContext {
    typealias Exporter = I
    
    private var handleFunc: (
        _: I.ExporterRequest,
        _: EventLoop,
        _: Bool
    ) -> EventLoopFuture<Response<AnyEncodable>>
    
    init<C: ConnectionContext>(from context: C) where C.Exporter == I {
        var context = context
        self.handleFunc = { request, eventLoop, final in
            context.handle(request: request, eventLoop: eventLoop, final: final)
        }
    }
    
    mutating func handle(request exporterRequest: I.ExporterRequest, eventLoop: EventLoop, final: Bool) -> EventLoopFuture<Response<AnyEncodable>> {
        self.handleFunc(exporterRequest, eventLoop, final)
    }
}

extension ConnectionContext {
    func eraseToAnyConnectionContext() -> AnyConnectionContext<Exporter> {
        AnyConnectionContext(from: self)
    }
}

struct InternalConnectionContext<H: Handler, I: InterfaceExporter>: ConnectionContext {
    typealias Exporter = I
    
    private let exporter: I
    
    private var validator: AnyValidator<I, EventLoop, ValidatedRequest<I, H>>
    
    private let endpoint: EndpointInstance<H>
    
    private var requestHandler: InternalEndpointRequestHandler<I, H> {
        InternalEndpointRequestHandler(endpoint: self.endpoint, exporter: self.exporter)
    }
    
    private var latestRequest: I.ExporterRequest?
    
    init(for exporter: I, on endpoint: Endpoint<H>) {
        self.exporter = exporter
        
        self.endpoint = EndpointInstance(from: endpoint)
        
        self.validator = endpoint.validator(for: exporter)
    }
    
    mutating func handle(
        request exporterRequest: I.ExporterRequest,
        eventLoop: EventLoop,
        final: Bool
    ) -> EventLoopFuture<Response<AnyEncodable>> {
        do {
            let newRequest = self.latestRequest?.reduce(to: exporterRequest) ?? exporterRequest
            
            let validatedRequest = try validator.validate(newRequest, with: eventLoop)
            
            self.latestRequest = newRequest
            
            return self.requestHandler(on: Connection(state: final ? .end : .open, request: validatedRequest))
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
}

extension ConnectionContext where Exporter.ExporterRequest: WithEventLoop {
    mutating func handle(request: Exporter.ExporterRequest) -> EventLoopFuture<Response<AnyEncodable>> {
        handle(request: request, eventLoop: request.eventLoop)
    }
    
    mutating func handle(request: Exporter.ExporterRequest, final: Bool) -> EventLoopFuture<Response<AnyEncodable>> {
        handle(request: request, eventLoop: request.eventLoop, final: final)
    }
}
