//
//  ConnectionContext.swift
//  
//
//  Created by Max Obermeier on 31.12.20.
//

import NIO
import ApodiniUtils
import Foundation

/// A type-erased version of ``ConnectionContext`` that wrapps ``Response/content``s into an
/// `AnyEncodable`
public struct AnyConnectionContext<I: InterfaceExporter> {
    private let _handleRequest: (I.ExporterRequest, EventLoop, Bool) -> EventLoopFuture<Response<AnyEncodable>>
    private let _handleRequestAndReturnParameters: (I.ExporterRequest, EventLoop, Bool) -> EventLoopFuture<(Response<AnyEncodable>, (UUID) -> Any?)>
    private let _handleEvent: (EventLoop, AnyObservedObject, TriggerEvent) -> EventLoopFuture<Response<AnyEncodable>>
    private let _register: (AnyObservedListener) -> Void
    
    fileprivate init<H: Handler>(_ context: ConnectionContext<I, H>) {
        self._handleRequest = context.handle
        self._handleRequestAndReturnParameters = context.handleAndReturnParameters
        self._handleEvent = context.handle
        self._register = context.register
    }
    
    /// This method is called for every request which is to be handled.
    /// - Parameters:
    ///   - exporterRequest: The exporter defined request to be handled.
    ///   - eventLoop: Defines the `EventLoop` on which the handling process should be run.
    ///   - final: True if this request is the last for the given Connection.
    /// - Returns: The response for the given Request.
    func handle(
        request exporterRequest: I.ExporterRequest,
        eventLoop: EventLoop,
        final: Bool
    ) -> EventLoopFuture<Response<AnyEncodable>> {
        _handleRequest(exporterRequest, eventLoop, `final`)
    }
    
    /// This method is called for every request which is to be handled.
    /// - Parameters:
    ///   - exporterRequest: The exporter defined request to be handled.
    ///   - eventLoop: Defines the `EventLoop` on which the handling process should be run.
    ///   - final: True if this request is the last for the given Connection.
    /// - Returns: The response for the given Request, along with a function that allows for fetching parameter's values based on their id.
    @available(*, deprecated, message: """
        This function currently only exists for RESTInterfaceExporter to work. Do not use if possible.
        A future rewrite of some elements of the `InterfaceExporter` API will replace this workaround with a
        more elegant solution.
    """)
    public func handleAndReturnParameters(
        request exporterRequest: I.ExporterRequest,
        eventLoop: EventLoop,
        final: Bool = true
    ) -> EventLoopFuture<(Response<AnyEncodable>, (UUID) -> Any?)> {
        _handleRequestAndReturnParameters(exporterRequest, eventLoop, final)
    }
    
    /// Runs through the context's handler with the state after the latest client-request.
    /// Should be used by exporters after an observed value in the context did change,
    /// to retrieve the proper message that has to be sent to the client.
    func handle(eventLoop: EventLoop, observedObject: AnyObservedObject, event: TriggerEvent) -> EventLoopFuture<Response<AnyEncodable>> {
        _handleEvent(eventLoop, observedObject, event)
    }
    
    /// Register a listener that will be notified once an observed object did change in the handler
    /// that is being used in this connection.
    func register<Listener: ObservedListener>(listener: Listener) {
        _register(AnyObservedListener(eventLoop: { listener.eventLoop }, onObservedDidChange: listener.onObservedDidChange))
    }
}

private extension AnyConnectionContext {
    struct AnyObservedListener: ObservedListener {
        private let _eventLoop: () -> EventLoop
        private let _onObservedDidChange: (AnyObservedObject, TriggerEvent) -> Void
        
        internal init(eventLoop: @escaping () -> EventLoop, onObservedDidChange: @escaping (AnyObservedObject, TriggerEvent) -> Void) {
            self._eventLoop = eventLoop
            self._onObservedDidChange = onObservedDidChange
        }
        
        var eventLoop: EventLoop {
            _eventLoop()
        }
        
        func onObservedDidChange(_ observedObject: AnyObservedObject, _ event: TriggerEvent) {
            _onObservedDidChange(observedObject, event)
        }
    }
}

/// An `ObservedListener` can be notified by a `ConnectionContext` if an observed object
/// in the connection's handler has changed.
public protocol ObservedListener {
    /// The `EventLoop` that is used by this connection to send service-streaming
    /// responses to the client.
    var eventLoop: EventLoop { get }

    /// Callback that will be called by a `ConnectionContext` if an observed value
    /// in the context's handler did change.
    func onObservedDidChange(_ observedObject: AnyObservedObject, _ event: TriggerEvent)
}


/// `ConnectionContext` holds the internal state of an endpoint for one connection
/// in a format suitable for a specific `InterfaceExporter`.
public class ConnectionContext<I: InterfaceExporter, H: Handler> {
    private let exporter: I
    private let endpoint: EndpointInstance<H>

    private var validator: AnyValidator<I, EventLoop, ValidatingRequest<I, H>>
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
    
    /// This method is called for every request which is to be handled.
    /// - Parameters:
    ///   - exporterRequest: The exporter defined request to be handled.
    ///   - eventLoop: Defines the `EventLoop` on which the handling process should be run.
    ///   - final: True if this request is the last for the given Connection.
    /// - Returns: The response for the given Request, along with a function that allows for fetching parameter's values based on their id.
    @available(*, deprecated, message: """
        This function currently only exists for RESTInterfaceExporter to work. Do not use if possible.
        A future rewrite of some elements of the `InterfaceExporter` API will replace this workaround with a
        more elegant solution.
    """)
    public func handleAndReturnParameters(
        request exporterRequest: I.ExporterRequest,
        eventLoop: EventLoop,
        final: Bool = true
    ) -> EventLoopFuture<(Response<H.Response.Content>, (UUID) -> Any?)> {
        let newRequest = self.latestRequest?.reduce(to: exporterRequest) ?? exporterRequest
        do {
            let validatingRequest = try validator.validate(newRequest, with: eventLoop)
            
            let connection = Connection(state: final ? .end : .open, request: validatingRequest)

            return requestHandler(with: validatingRequest, on: connection)
                .map { result in
                    self.latestRequest = newRequest
                    return (result, { uuid in try? validatingRequest.retrieveAnyParameter(uuid) })
                }
                .flatMapErrorThrowing { error in
                    if let apodiniError = error as? ApodiniError {
                        if apodiniError.option(for: .errorType) != .badInput {
                            self.latestRequest = newRequest
                        }
                    } else {
                        self.latestRequest = newRequest
                    }
                    throw error
                }
        } catch {
            if let apodiniError = error as? ApodiniError {
                if apodiniError.option(for: .errorType) != .badInput {
                    self.latestRequest = newRequest
                }
            } else {
                self.latestRequest = newRequest
            }
            
            return eventLoop.makeFailedFuture(error)
        }
    }
    
    /// This method is called for every request which is to be handled.
    /// - Parameters:
    ///   - exporterRequest: The exporter defined request to be handled.
    ///   - eventLoop: Defines the `EventLoop` on which the handling process should be run.
    ///   - final: True if this request is the last for the given Connection.
    /// - Returns: The response for the given Request.
    public func handle(
        request exporterRequest: I.ExporterRequest,
        eventLoop: EventLoop,
        final: Bool = true
    ) -> EventLoopFuture<Response<H.Response.Content>> {
        self.handleAndReturnParameters(
            request: exporterRequest,
            eventLoop: eventLoop,
            final: final)
        .map { response, _ in
            response
        }
    }

    /// Runs through the context's handler with the state after the latest client-request.
    /// Should be used by exporters after an observed value in the context did change,
    /// to retrieve the proper message that has to be sent to the client.
    public func handle(
        eventLoop: EventLoop,
        observedObject: AnyObservedObject,
        event: TriggerEvent) -> EventLoopFuture<Response<H.Response.Content>> {
        guard !event.cancelled else {
            return eventLoop.makeSucceededFuture(.nothing)
        }
        
        observedObject.setChanged(to: true, reason: event)
        do {
            guard let latestRequest = latestRequest else {
                fatalError("Can only handle changes to observed object after an initial client-request")
            }
            let validatingRequest = try validator.validate(latestRequest, with: eventLoop)
            let connection = Connection(state: .open, request: validatingRequest)

            return self.requestHandler(with: validatingRequest, on: connection).map { response in
                observedObject.setChanged(to: false, reason: event)
                return response
            }
        } catch {
            observedObject.setChanged(to: false, reason: event)
            return eventLoop.makeFailedFuture(error)
        }
    }

    /// Register a listener that will be notified once an observed object did change in the handler
    /// that is being used in this connection.
    public func register<Listener: ObservedListener>(listener: Listener) {
        // register the given listener for notifications on the handler
        for object in collectObservedObjects(from: endpoint.handler) {
            self.observations.append(object.register { triggerEvent in
                listener.onObservedDidChange(object, triggerEvent)
            })
        }
    }
}

// MARK: Exporter Request with EventLoop
public extension ConnectionContext where I.ExporterRequest: ExporterRequestWithEventLoop {
    /// This method is called for every request which is to be handled.
    /// Shorthand method for the case where the exporter request conforms to `ExporterRequestWithEventLoop`.
    /// - Parameters:
    ///   - exporterRequest: The exporter defined request to be handled.
    ///   - final: True if this request is the last for the given Connection.
    /// - Returns: The response for the given Request.
    func handle(request: I.ExporterRequest, final: Bool = true) -> EventLoopFuture<Response<H.Response.Content>> {
        handle(request: request, eventLoop: request.eventLoop, final: final)
    }
}

extension ConnectionContext {
    fileprivate func handle(
        request exporterRequest: I.ExporterRequest,
        eventLoop: EventLoop,
        final: Bool) -> EventLoopFuture<Response<AnyEncodable>> {
        self.handle(
            request: exporterRequest,
            eventLoop: eventLoop,
            final: final)
        .map { (response: Response<H.Response.Content>) in
            response.typeErasured
        }
    }
    
    fileprivate func handleAndReturnParameters(
        request exporterRequest: I.ExporterRequest,
        eventLoop: EventLoop,
        final: Bool) -> EventLoopFuture<(Response<AnyEncodable>, (UUID) -> Any?)> {
        self.handleAndReturnParameters(
            request: exporterRequest,
            eventLoop: eventLoop,
            final: final)
        .map { (response: Response<H.Response.Content>, parameters) in
            (response.typeErasured, parameters)
        }
    }
    
    fileprivate func handle(eventLoop: EventLoop, observedObject: AnyObservedObject, event: TriggerEvent) -> EventLoopFuture<Response<AnyEncodable>> {
        self.handle(
            eventLoop: eventLoop,
            observedObject: observedObject,
            event: event)
        .map { (response: Response<H.Response.Content>) in
            response.typeErasured
        }
    }
    
    /// A type-erased wrapper around this ``ConnectionContext``.
    public var typeErased: AnyConnectionContext<I> {
        AnyConnectionContext(self)
    }
}
