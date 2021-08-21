//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

#if DEBUG || RELEASE_TESTING
@testable import Apodini
@testable import ApodiniExtension
import struct Foundation.UUID
@testable import ApodiniREST
import ApodiniVaporSupport
import Vapor

// MARK: Mock ConnectionContext

/// A wrapper around a `Delegate` that allows for evaluating it with a
/// certain `Input`.  The evaluation comes with the complete standard
/// set of validation mechanisms. Furthermore, the ``ConnectionContext`` also
/// takes care of observing the `Delegate`.
public class ConnectionContext<Input, H: Handler> {
    let delegate: Delegate<H>
    
    let strategy: AnyDecodingStrategy<Input>
    
    let defaults: DefaultValueStore
    
    var listeners: [ObservedListener] = []
    
    var observation: Observation?
    
    var latestRequest: MutabilityValidatingRequest<DefaultValueStore.DefaultInsertingRequest>?
    
    internal init(delegate: Delegate<H>, strategy: AnyDecodingStrategy<Input>, defaults: DefaultValueStore) {
        self.strategy = strategy
        self.defaults = defaults
        self.delegate = delegate
    }
    
    /// Evaluate the inner `Delegate` using the given `request`.
    public func handle(request: Input, eventLoop: EventLoop, final: Bool = true) -> EventLoopFuture<Apodini.Response<H.Response.Content>> {
        self.handleAndReturnParameters(request: request, eventLoop: eventLoop, final: final).map { response, _ in response }
    }
    
    /// Evaluate the inner `Delegate` using the given `request` while also providing a callback that returns the value for all
    /// decoded input parameters based on the parameter's id.
    public func handleAndReturnParameters(
        request: Input,
        eventLoop: EventLoop,
        final: Bool = true) -> EventLoopFuture<(Apodini.Response<H.Response.Content>, (UUID) -> Any?)> {
        if self.observation == nil {
            self.observation = delegate.register { event in
                self.listeners.forEach { listener in listener.onObservedDidChange(self.delegate, event) }
            }
        }
        
        let request = strategy
                        .decodeRequest(from: request, with: (request as? RequestBasis) ?? DefaultRequestBasis(base: request), with: eventLoop)
                        .insertDefaults(with: defaults)
        
        self.latestRequest = latestRequest?.reduce(with: request) ?? MutabilityValidatingRequest(request)
        
        let cachingRequest = latestRequest!.cache()
        
        return cachingRequest.evaluate(on: delegate, final ? .end : .open).map { response in (response, cachingRequest.peak(_:)) }
    }
    
    /// Evaluate the inner `Delegate` based on the given `event`.
    public func handle(
        eventLoop: EventLoop,
        observedObject: AnyObservedObject? = nil,
        event: TriggerEvent) -> EventLoopFuture<Apodini.Response<H.Response.Content>> {
        guard let request = self.latestRequest else {
            fatalError("Mock ConnectionContext tried to handle event before a Request was present.")
        }
        
        return delegate.evaluate(event, using: request.cache(), with: .open)
    }
    
    /// Register an `ObservedListener` to be called whenever an `ObservableObject` observed by the `Delegate`
    /// is triggered.
    public func register(listener: ObservedListener) {
        listeners.append(listener)
    }
}

public extension ConnectionContext where Input: WithEventLoop {
    /// Evaluate the inner `Delegate` using the given `request`.
    func handle(request: Input, final: Bool = true) -> EventLoopFuture<Apodini.Response<H.Response.Content>> {
        handle(request: request, eventLoop: request.eventLoop, final: final)
    }
}

/// Something that brings an NIO `EventLoop`.
public protocol WithEventLoop {
    /// The `EventLoop` associated with this object.
    var eventLoop: EventLoop { get }
}

extension Vapor.Request: WithEventLoop { }

extension Endpoint {
    /// Create a ``ConnectionContext`` for a ApodiniExtension `LegacyInterfaceExporter`.
    public func createConnectionContext<IE: LegacyInterfaceExporter>(for exporter: IE) -> ConnectionContext<IE.ExporterRequest, H> {
        ConnectionContext(delegate: self[DelegateFactory<H, IE>.self].instance(),
                          strategy: InterfaceExporterLegacyStrategy(exporter).applied(to: self).typeErased,
                          defaults: self[DefaultValueStore.self])
    }
    
    /// Create a ``ConnectionContext`` for any object that can provide a fitting strategy for decoding its ``EndpointDecodingStrategyProvider/Input``.
    public func createConnectionContext<IE: EndpointDecodingStrategyProvider>(for exporter: IE) -> ConnectionContext<IE.Input, H> {
        ConnectionContext(delegate: self[DelegateFactory<H, RESTInterfaceExporter>.self].instance(),
                          strategy: exporter.strategy.applied(to: self).typeErased,
                          defaults: self[DefaultValueStore.self])
    }
}

/// A type which provides a fixed ApodiniExtension `EndpointDecodingStrategy` that
/// can decode the ``Input``
public protocol EndpointDecodingStrategyProvider {
    /// The type that the associated strategy can decode.
    associatedtype Input
    
    /// The strategy for decoding the associated ``Input``
    var strategy: AnyEndpointDecodingStrategy<Input> { get }
}

extension RESTInterfaceExporter: EndpointDecodingStrategyProvider {
    public var strategy: AnyEndpointDecodingStrategy<Vapor.Request> {
        ParameterTypeSpecific(
                            lightweight: LightweightStrategy(),
                            path: PathStrategy(useNameAsIdentifier: false),
                            content: AllIdentityStrategy(exporterConfiguration.decoder).transformedToVaporRequestBasedStrategy()
        ).typeErased
    }
}

/// An object that can be called whenever a `TriggerEvent` is raised.
public protocol ObservedListener {
    /// The function to be called whenever a `TriggerEvent` is raised.
    func onObservedDidChange(_ observedObject: AnyObservedObject, _ event: TriggerEvent)
}

#endif
