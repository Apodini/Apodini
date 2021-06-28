//
//  MockConnectionContext.swift
//  
//
//  Created by Max Obermeier on 28.06.21.
//


#if DEBUG || RELEASE_TESTING
@testable import Apodini
@testable import ApodiniExtension
import struct Foundation.UUID
@testable import ApodiniREST
import ApodiniVaporSupport
import Vapor
import ApodiniREST

// MARK: Mock ConnectionContext
public class ConnectionContext<Input, H: Handler> {
    var delegate: Delegate<H>
    
    let strategy: AnyDecodingStrategy<Input>
    
    let defaults: DefaultValueStore
    
    var listeners: [ObservedListener] = []
    
    var observation: Observation?
    
    var latestRequest: MutabilityValidatingRequest<DefaultValueStore.DefaultInsertingRequest>?
    
    internal init(delegate: Delegate<H>, strategy: AnyDecodingStrategy<Input>, defaults: DefaultValueStore) {
        self.strategy = strategy
        self.defaults = defaults
        self.delegate = delegate
        
        
        self.delegate.activate()
    }
    
    public func handle(request: Input, eventLoop: EventLoop, final: Bool = true) -> EventLoopFuture<Apodini.Response<H.Response.Content>> {
        self.handleAndReturnParameters(request: request, eventLoop: eventLoop, final: final).map { (response, _) in response }
    }
    
    public func handleAndReturnParameters(request: Input, eventLoop: EventLoop, final: Bool = true) -> EventLoopFuture<(Apodini.Response<H.Response.Content>, (UUID) -> Any?)> {
        if self.observation == nil {
            self.observation = delegate.register({ event in
                self.listeners.forEach { listener in listener.onObservedDidChange(self.delegate, event) }
            })
        }
        
        let request = strategy
                        .decodeRequest(from: request, with: (request as? RequestBasis) ?? DefaultRequestBasis(base: request), with: eventLoop)
                        .insertDefaults(with: defaults)
        
        self.latestRequest = latestRequest?.reduce(with: request) ?? MutabilityValidatingRequest(request)
        
        let cachingRequest = latestRequest!.cache()
        
        return cachingRequest.evaluate(on: &delegate, final ? .end : .open).map { response in (response, cachingRequest.peak(_:)) }
    }
    
    public func handle(eventLoop: EventLoop, observedObject: AnyObservedObject? = nil, event: TriggerEvent) -> EventLoopFuture<Apodini.Response<H.Response.Content>> {
        guard let request = self.latestRequest else {
            fatalError("Mock ConnectionContext tried to handle event before a Request was present.")
        }
        
        return delegate.evaluate(event, using: request.cache(), with: .open)
    }
    
    public func register(listener: ObservedListener) {
        listeners.append(listener)
    }
}

public extension ConnectionContext where Input: WithEventLoop {
    func handle(request: Input, final: Bool = true) -> EventLoopFuture<Apodini.Response<H.Response.Content>> {
        handle(request: request, eventLoop: request.eventLoop, final: final)
    }
}

public protocol WithEventLoop {
    var eventLoop: EventLoop { get }
}

extension Vapor.Request: WithEventLoop { }

extension Endpoint {
    public func createConnectionContext<IE: LegacyInterfaceExporter>(for exporter: IE) -> ConnectionContext<IE.ExporterRequest, H> {
        ConnectionContext(delegate: Delegate(handler, .required),
                          strategy: InterfaceExporterLegacyStrategy(exporter).applied(to: self).typeErased,
                          defaults: self[DefaultValueStore.self])
    }
    
    public func createConnectionContext<IE: EndpointDecodingStrategyProvider>(for exporter: IE) -> ConnectionContext<IE.Input, H> {
        ConnectionContext(delegate: Delegate(handler, .required),
                          strategy: exporter.strategy.applied(to: self).typeErased,
                          defaults: self[DefaultValueStore.self])
    }
}

public protocol EndpointDecodingStrategyProvider {
    associatedtype Input
    
    var strategy: AnyEndpointDecodingStrategy<Input> { get }
}

extension RESTInterfaceExporter: EndpointDecodingStrategyProvider {
    public var strategy: AnyEndpointDecodingStrategy<Vapor.Request> {
        ParameterTypeSpecific(
                .lightweight,
                using: LightweightStrategy(),
                otherwise: ParameterTypeSpecific(
                            .path,
                            using: PathStrategy(),
                            otherwise: AllIdentityStrategy(exporterConfiguration.decoder).transformedToVaporRequestBasedStrategy()
                )).typeErased
    }
}

public protocol ObservedListener {
    func onObservedDidChange(_ observedObject: AnyObservedObject, _ event: TriggerEvent)
}

#endif
