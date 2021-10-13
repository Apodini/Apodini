//
//  MockRequestHandler.swift
//  
//
//  Created by Paul Schmiedmayer on 7/11/21.
//

import ApodiniExtension


protocol AnyMockRequestHandler {
    var anyEndpoint: AnyEndpoint { get }
    
    func handle<R: Encodable>(_ request: MockRequest<R>) throws -> Apodini.Response<R>
    func register(_ listener: ObservedListener) throws
}


class MockRequestHandler<H: Handler>: AnyMockRequestHandler {
    let endpoint: Endpoint<H>
    let eventLoop: EventLoop
    private(set) var delegate: Delegate<H>
    private(set) var listeners: [ObservedListener] = []
    private(set) var observation: Observation?
    
    
    var anyEndpoint: AnyEndpoint {
        endpoint
    }
    
    
    init(_ endpoint: Endpoint<H>, eventLoop: EventLoop) {
        self.endpoint = endpoint
        self.eventLoop = eventLoop
        self.delegate = Delegate(endpoint.handler, .required)
    }
    
    
    func handle<R: Encodable>(_ request: MockRequest<R>) throws -> Apodini.Response<R> {
        guard let response = try handle(AnyMockRequest(request)) as? Apodini.Response<R> else {
            throw MockExporterError.noMatchingContentType(description: "\(R.self) does not match Handler Content type \(H.Response.Content.self)")
        }
        return response
    }
    
    func handle(_ request: AnyMockRequest) throws -> Apodini.Response<H.Response.Content> {
        let strategy = MockInterfaceExporter.decodingStrategy(for: endpoint)
        
        return try strategy
            .decodeRequest(from: request, with: eventLoop)
            .insertDefaults(with: endpoint[DefaultValueStore.self])
            .cache()
            .evaluate(on: &delegate)
            .wait()
    }
    
    func register(_ listener: ObservedListener) throws {
        listeners.append(listener)
        
        self.observation = delegate.register { event in
            for listener in self.listeners {
                listener.onObservedDidChange(self.delegate, event)
            }
        }
    }
}
