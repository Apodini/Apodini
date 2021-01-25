//
//  ConnectionContext.swift
//  
//
//  Created by Max Obermeier on 31.12.20.
//

import Foundation
import Fluent

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

/// An `ObservedListener` can be notified by a `ConnectionContext` if an observed object
/// in the connections handler has changed.
protocol ObservedListener {
    /// The `EventLoop` that is used by this connection to send service-streaming
    /// responses to the client.
    var eventLoop: EventLoop { get }

    func onObservedDidChange(in handler: AnyHandler)
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

    /// Register a listener that will be notified once an observed object did change in the handler
    /// that is being used in this connection.
    mutating func register(listener: ObservedListener)
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

    private var registerFunc: (
        _: ObservedListener
    ) -> Void
    
    init<C: ConnectionContext>(from context: C) where C.Exporter == I {
        var context = context
        self.handleFunc = { request, eventLoop, final in
            context.handle(request: request, eventLoop: eventLoop, final: final)
        }
        self.registerFunc = { listener in
            context.register(listener: listener)
        }
    }
    
    mutating func handle(request exporterRequest: I.ExporterRequest, eventLoop: EventLoop, final: Bool) -> EventLoopFuture<Response<AnyEncodable>> {
        self.handleFunc(exporterRequest, eventLoop, final)
    }

    mutating func register(listener: ObservedListener) {
        self.registerFunc(listener)
    }
}

extension ConnectionContext {
    func eraseToAnyConnectionContext() -> AnyConnectionContext<Exporter> {
        AnyConnectionContext(from: self)
    }
}

class InternalConnectionContext<H: Handler, I: InterfaceExporter>: ConnectionContext {
    typealias Exporter = I
    typealias ConnectionHandler = H
    
    private let exporter: I
    
    private var validator: AnyValidator<I, EventLoop, ValidatedRequest<I, H>>
    
    var endpoint: EndpointInstance<H>
    
    private var requestHandler: InternalEndpointRequestHandler<I, H> {
        InternalEndpointRequestHandler(endpoint: self.endpoint, exporter: self.exporter)
    }
    
    private var latestRequest: I.ExporterRequest?
    
    init(for exporter: I, on endpoint: Endpoint<H>) {
        self.exporter = exporter
        
        self.endpoint = EndpointInstance(from: endpoint)
        
        self.validator = endpoint.validator(for: exporter)
    }
    
    func handle(
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

    func register(listener: ObservedListener) {
        // register the given listener for notifications on the handler
        for obj in endpoint.handler.collectObservedObjects() {
            obj.valueDidChange = {
                listener.onObservedDidChange(in: AnyHandler(self.endpoint.handler))
            }
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
