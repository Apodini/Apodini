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
/// in the connection's handler has changed.
protocol ObservedListener {
    /// The `EventLoop` that is used by this connection to send service-streaming
    /// responses to the client.
    var eventLoop: EventLoop { get }

    /// Callback that will be called by a `ConnectionContext` if an observed value
    /// in the context's handler did change.
    func onObservedDidChange<C: ConnectionContext>(_ observedObject: AnyObservedObject, in context: C)
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

    /// Runs through the context's handler with the state after the latest client-request.
    /// Should be used by exporters after an observed value in the context did change,
    /// to retrieve the proper message that has to be sent to the client.
    func handle(eventLoop: EventLoop, observedObject: AnyObservedObject) -> EventLoopFuture<Response<AnyEncodable>>

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

    private var handleObservedChanged: (
        _: EventLoop,
        _: AnyObservedObject
    ) -> EventLoopFuture<Response<AnyEncodable>>

    private var registerFunc: (
        _: ObservedListener
    ) -> Void
    
    init<C: ConnectionContext>(from context: C) where C.Exporter == I {
        var context = context
        self.handleFunc = { request, eventLoop, final in
            context.handle(request: request, eventLoop: eventLoop, final: final)
        }
        self.handleObservedChanged = { eventLoop, observedObject in
            context.handle(eventLoop: eventLoop, observedObject: observedObject)
        }
        self.registerFunc = { listener in
            context.register(listener: listener)
        }
    }
    
    mutating func handle(request exporterRequest: I.ExporterRequest, eventLoop: EventLoop, final: Bool) -> EventLoopFuture<Response<AnyEncodable>> {
        self.handleFunc(exporterRequest, eventLoop, final)
    }

    func handle(eventLoop: EventLoop, observedObject: AnyObservedObject) -> EventLoopFuture<Response<AnyEncodable>> {
        self.handleObservedChanged(eventLoop, observedObject)
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
    
    private let endpoint: EndpointInstance<H>
    
    private var requestHandler: InternalEndpointRequestHandler<I, H> {
        InternalEndpointRequestHandler(endpoint: self.endpoint, exporter: self.exporter)
    }
    
    private var latestRequest: I.ExporterRequest?
    
    private var observations: [Observation] = []
    
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

    func handle(eventLoop: EventLoop, observedObject: AnyObservedObject) -> EventLoopFuture<Response<AnyEncodable>> {
        observedObject.changed = true
        do {
            guard let latestRequest = latestRequest else {
                fatalError("Can only handle changes to observed object after an initial client-request")
            }
            let validatedRequest = try validator.validate(latestRequest, with: eventLoop)
            return self.requestHandler(on: Connection(state: .open, request: validatedRequest)).map { response in
                observedObject.changed = false
                return response
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    func register(listener: ObservedListener) {
        // register the given listener for notifications on the handler
        for object in endpoint.handler.collectObservedObjects() {
            self.observations.append(object.register {
                listener.onObservedDidChange(object, in: self)
            })
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
