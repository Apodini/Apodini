//
//  RemoteHandlerInvocationManager.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-14.
//

import Foundation
import NIO


/// A stand-in helper function to create `Swift.Error`-conforming objects without having to define a custom error type
internal func makeApodiniError(code: Int = 0, _ message: String) -> Swift.Error {
    NSError(domain: "Apodini", code: code, userInfo: [
        NSLocalizedDescriptionKey: message
    ])
}


/// Helper type which stores a parameter for a remote handler invocation.
public struct CollectedParameter<HandlerType: InvocableHandler> {
    /// The (partially type-erased) key path into the handler, to the `Parameter<>.ID` object of the parameter this value references
    let handlerKeyPath: PartialKeyPath<HandlerType>
    /// The parameter value
    let value: Any
    
    /// Type-safe way to define a parameter passed to a remote invocation
    public init<Value>(_ keyPathIntoHandler: KeyPath<HandlerType, Parameter<Value>.ID>, _ value: Value) {
        self.handlerKeyPath = keyPathIntoHandler
        self.value = value
    }
    
    /// Internal, type-erased initializer
    internal init(handlerKeyPath: PartialKeyPath<HandlerType>, value: Any) {
        self.handlerKeyPath = handlerKeyPath
        self.value = value
    }
}


/// The `RemoteHandlerInvocationManager` implements the user-facing API for invoking handlers from within a handler.
/// A handler which wishes to access other (invocable) handler's functionality defines a private property of this type.
/// See [the documentation](https://github.com/Apodini/Apodini/blob/develop/Documentation/Components/Inter-Component%20Communication.md) for more info.
public struct RemoteHandlerInvocationManager: RequestInjectable {
    private var requestEventLoop: EventLoop?
    /// Find an event loop somewhere in the current environment.
    /// Realistically getting an event loop shouln't be an issue,
    /// since the remote handler invocation APIs can only be accessed from within a `handle()` function,
    /// and in that situation we can access the request's event loop.
    private var eventLoop: EventLoop {
        if let eventLoop = requestEventLoop {
            return eventLoop
        } else if let eventLoop = RHIInterfaceExporter.shared?.app.eventLoopGroup.next() {
            return eventLoop
        } else {
            fatalError("Unable to find an event loop")
        }
    }
    
    /// This is the initializer
    public init() {}
    
    mutating func inject(using request: Request) {
        requestEventLoop = request.eventLoop
    }
}

extension RemoteHandlerInvocationManager {
    /// Invoke an invocable handler from within your handler.
    /// - parameter handlerType: The static type of the `InvocableHandler` you wish to invoke
    /// - parameter handlerId: The identifier of the to-be-invoked handler. This is required to locate the handler within the web service.
    /// - parameter parameters: The parameters to be passed to to the invoked handler
    public func invoke<H: InvocableHandler>(
        _ handlerType: H.Type,
        identifiedBy handlerId: H.HandlerIdentifier,
        parameters: H.ParametersStorage
    ) -> EventLoopFuture<H.Response.Content> {
        _invoke(
            handlerType: H.self,
            handlerId: handlerId,
            collectedInputParams: H.ParametersStorage.mapping.map { mappingEntry in
                CollectedParameter<H>(
                    handlerKeyPath: mappingEntry.handlerKeyPath,
                    value: parameters[keyPath: mappingEntry.paramsStructKeyPath]
                )
            }
        )
    }
    
    // If the type doesn't specify a `Parameters` struct (ie, H.Parameters still is the _NoParameters default type),
    // we enable the `CollectedParameter` API.
    // This means that the developer of a Handler can force the user of the -invoke API to use the handler-provided Params type,
    // and that using the (somewhat worse, because unable to compile-time-check completion) collected params api isn't available.
    /// Invoke an invocable handler from within your handler.
    /// - parameter handlerType: The static type of the `InvocableHandler` you wish to invoke
    /// - parameter handlerId: The identifier of the to-be-invoked handler. This is required to locate the handler within the web service.
    /// - parameter parameters: The parameters to be passed to to the invoked handler
    public func invoke<H: InvocableHandler>(
        _ handlerType: H.Type,
        identifiedBy handlerId: H.HandlerIdentifier,
        parameters: [CollectedParameter<H>] = []
    ) -> EventLoopFuture<H.Response.Content> where H.ParametersStorage == InvocableHandlerEmptyParametersStorage<H> {
        _invoke(handlerType: handlerType, handlerId: handlerId, collectedInputParams: parameters)
    }
    
    
    private func _invoke<H: InvocableHandler>(
        handlerType: H.Type,
        handlerId: H.HandlerIdentifier,
        collectedInputParams: [CollectedParameter<H>]
    ) -> EventLoopFuture<H.Response.Content> {
        guard let RHIIE = RHIInterfaceExporter.shared else {
            return eventLoop.makeFailedFuture(makeApodiniError("unable to get \(RHIInterfaceExporter.self) object"))
        }
        
        guard let targetEndpoint: Endpoint<H> = RHIIE.getEndpoint(withIdentifier: handlerId, ofType: H.self) else {
            return eventLoop.makeFailedFuture(makeApodiniError("Unable to find target endpoint. (handlerId: '\(handlerId)', handlerType: '\(H.self)')"))
        }
        
        let request = RHIInterfaceExporter.ExporterRequest(endpoint: targetEndpoint, collectedParameters: collectedInputParams)
        var context = targetEndpoint.createConnectionContext(for: RHIIE)
        let responseFuture: EventLoopFuture<Response<AnyEncodable>> = context.handle(request: request, eventLoop: self.eventLoop)
        return responseFuture.flatMapThrowing { (response: Response<AnyEncodable>) -> H.Response.Content in
            switch response {
            case .final(let anyEncodable):
                if let value = anyEncodable.typed(H.Response.Content.self) {
                    return value
                } else {
                    throw makeApodiniError("Unable to convert response to expected type '\(H.Response.Content.self)'")
                }
            default:
                throw makeApodiniError("Unexpected response value: \(response). Expected '.final'.")
            }
        }
    }
}
