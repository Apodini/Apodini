//
//  ConnectionContext.swift
//  
//
//  Created by Max Obermeier on 31.12.20.
//

import NIO

/// An `ObservedListener` can be notified by a `ConnectionContext` if an observed object
/// in the connection's handler has changed.
public protocol ObservedListener {
    /// Defines the InterfaceExporter used for thus `ObservedListener`
    associatedtype Exporter: InterfaceExporter

    /// The `EventLoop` that is used by this connection to send service-streaming
    /// responses to the client.
    var eventLoop: EventLoop { get }

    /// Callback that will be called by a `ConnectionContext` if an observed value
    /// in the context's handler did change.
    func onObservedDidChange(_ observedObject: AnyObservedObject, in context: ConnectionContext<Exporter>)
}

/// `ConnectionContext` holds the internal state of an endpoint for one connection
/// in a format suitable for a specific `InterfaceExporter`.
public class ConnectionContext<Exporter: InterfaceExporter> {
    fileprivate init() {
        // Marked private as nobody is allowed to instantiate a `ConnectionContext` directly
        // fileprivate because `InternalConnectionContext` still needs to call it
    }

    /// This method is called for every request which is to be handled.
    /// - Parameters:
    ///   - exporterRequest: The exporter defined request to be handled.
    ///   - eventLoop: Defines the `EventLoop` on which the handling process should be run.
    ///   - final: True if this request is the last for the given Connection.
    /// - Returns: The response for the given Request.
    public func handle(
        request _: Exporter.ExporterRequest,
        eventLoop _: EventLoop,
        connectionState _: ConnectionState = .end
    ) -> EventLoopFuture<Response<EnrichedContent>> {
        fatalError("""
                   A ConnectionContext<\(Exporter.self)> (\(self)) was constructed without properly \
                   overriding the handle(request:eventLoop:connectionState:) function.
                   """)
    }

    /// Runs through the context's handler with the state after the latest client-request.
    /// Should be used by exporters after an observed value in the context did change,
    /// to retrieve the proper message that has to be sent to the client.
    public func handle(eventLoop _: EventLoop, observedObject _: AnyObservedObject) -> EventLoopFuture<Response<EnrichedContent>> {
        fatalError("""
                   A ConnectionContext<\(Exporter.self)> (\(self)) was constructed without properly \
                   overriding the handle(request:observedObject:) function.
                   """)
    }

    /// Register a listener that will be notified once an observed object did change in the handler
    /// that is being used in this connection.
    public func register<Listener: ObservedListener>(listener _: Listener) where Listener.Exporter == Exporter {
        fatalError("A ConnectionContext<\(Exporter.self)> (\(self)) was constructed without properly overriding the register(...) function.")
    }
}

// MARK: Exporter Request with EventLoop
public extension ConnectionContext where Exporter.ExporterRequest: WithEventLoop {
    /// This method is called for every request which is to be handled.
    /// Shorthand method for the case where the exporter request conforms to `WithEventLoop`.
    /// - Parameters:
    ///   - exporterRequest: The exporter defined request to be handled.
    ///   - final: True if this request is the last for the given Connection.
    /// - Returns: The response for the given Request.
    func handle(request: Exporter.ExporterRequest, final: ConnectionState = .end) -> EventLoopFuture<Response<EnrichedContent>> {
        handle(request: request, eventLoop: request.eventLoop, connectionState: final)
    }
}


class EndpointSpecificConnectionContext<I: InterfaceExporter, H: Handler>: ConnectionContext<I> {
    private let exporter: I
    private let endpoint: EndpointInstance<H>

    private var validator: AnyValidator<I, EventLoop, ValidatedRequest<I, H>>
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
    
    override func handle(
        request exporterRequest: I.ExporterRequest,
        eventLoop: EventLoop,
        connectionState: ConnectionState = .end
    ) -> EventLoopFuture<Response<EnrichedContent>> {
        do {
            let newRequest = self.latestRequest?.reduce(to: exporterRequest) ?? exporterRequest
            let validatedRequest = try validator.validate(newRequest, with: eventLoop)
            
            self.latestRequest = newRequest

            let connection = Connection(state: connectionState, request: validatedRequest)

            return requestHandler(with: validatedRequest, on: connection)
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    override func handle(eventLoop: EventLoop, observedObject: AnyObservedObject) -> EventLoopFuture<Response<EnrichedContent>> {
        observedObject.changed = true
        do {
            guard let latestRequest = latestRequest else {
                fatalError("Can only handle changes to observed object after an initial client-request")
            }
            let validatedRequest = try validator.validate(latestRequest, with: eventLoop)
            let connection = Connection(state: .open, request: validatedRequest)

            return self.requestHandler(with: validatedRequest, on: connection).map { response in
                observedObject.changed = false
                return response
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    override func register<Listener: ObservedListener>(listener: Listener) where Listener.Exporter == I {
        // register the given listener for notifications on the handler
        for object in endpoint.handler.collectObservedObjects() {
            self.observations.append(object.register {
                listener.onObservedDidChange(object, in: self)
            })
        }
    }
}
