//
//  RemoteHandlerInvocationManager.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-14.
//

import Foundation
import NIO
import Apodini
import ApodiniDeployBuildSupport
import ApodiniDeployRuntimeSupport
import ApodiniVaporSupport
@_implementationOnly import Vapor


/// A stand-in helper function to create `Swift.Error`-conforming objects without having to define a custom error type
internal func makeApodiniError(code: Int = 0, _ message: String) -> Swift.Error {
    NSError(domain: "Apodini", code: code, userInfo: [
        NSLocalizedDescriptionKey: message
    ])
}




/// Helper type which stores a parameter for a remote handler invocation.
public struct CollectedParameter<HandlerType: Handler> {
    /// The (partially type-erased) key path into the handler, to the `Parameter<>.ID` object of the parameter this value references
    let handlerKeyPath: PartialKeyPath<HandlerType>
    /// The parameter value
    let value: Any
    
    /// Type-safe way to define a parameter passed to a remote invocation
    public init<Value>(_ keyPathIntoHandler: KeyPath<HandlerType, Parameter<Value>.ID>, _ value: Value) where HandlerType: InvocableHandler {
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
public struct RemoteHandlerInvocationManager {
    private let app: Apodini.Application
    
    private var eventLoop: EventLoop {
        app.eventLoopGroup.next()
    }
    
    /// This is the initializer
    internal init(app: Apodini.Application) {
        self.app = app
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
        guard let RHIIE = ApodiniDeployInterfaceExporter.shared else {
            return eventLoop.makeFailedFuture(makeApodiniError("unable to get \(ApodiniDeployInterfaceExporter.self) object"))
        }
        
        guard let targetEndpoint: Endpoint<H> = RHIIE.getEndpoint(withIdentifier: handlerId, ofType: H.self) else {
            return eventLoop.makeFailedFuture(makeApodiniError("Unable to find target endpoint. (handlerId: '\(handlerId)', handlerType: '\(H.self)')"))
        }
        
        switch dispatchStrategy(forInvocationOf: targetEndpoint, RHIIE: RHIIE) {
        case .locally:
            return targetEndpoint._invoke(withCollectedParameters: collectedInputParams, RHIIE: RHIIE, on: eventLoop)
//            let request = ApodiniDeployInterfaceExporter.ExporterRequest(endpoint: targetEndpoint, collectedParameters: collectedInputParams)
//            var context = targetEndpoint.createConnectionContext(for: RHIIE)
//            let responseFuture: EventLoopFuture<Response<AnyEncodable>> = context.handle(request: request, eventLoop: self.eventLoop)
//            return responseFuture.flatMapThrowing { (response: Response<AnyEncodable>) -> H.Response.Content in
//                switch response {
//                case .final(let anyEncodable):
//                    if let value = anyEncodable.typed(H.Response.Content.self) {
//                        return value
//                    } else {
//                        throw makeApodiniError("Unable to convert response to expected type '\(H.Response.Content.self)'")
//                    }
//                default:
//                    throw makeApodiniError("Unexpected response value: \(response). Expected '.final'.")
//                }
//            }
        case .remotely(let targetNode):
            guard let runtime = RHIIE.deploymentProviderRuntime else {
                // TODO maybe just dispatch locally if we cant find a runtime?
                return eventLoop.makeFailedFuture(makeApodiniError("Unable to find runtime"))
            }
            // The targetEndpoint is on a different node, dispatch the invocation there
            
            // TODO if theres a guarantee that an EndpointParameter's id is the same as the id of the @Parameter it was generated from,
            // we can combine these two sets into one
            var alreadyProcessedParamKeyPaths: Set<AnyKeyPath> = []
            var alreadyProcessedEndpointParamIds: Set<UUID> = []

            let invocationParams: [HandlerInvocationParameter] = collectedInputParams.map { collectedParam in
                // The @Parameter property wrapper declaration in the handler
                let handlerParamId = (targetEndpoint.handler[keyPath: collectedParam.handlerKeyPath] as! AnyParameterID).value
                let endpointParam = targetEndpoint.findParameter(for: handlerParamId)!
                if !alreadyProcessedParamKeyPaths.insert(collectedParam.handlerKeyPath).inserted {
                    print("Parameter '\(endpointParam.name)' specified multiple times in remote handler invocation")
                }
                if !alreadyProcessedEndpointParamIds.insert(endpointParam.id).inserted {
                    print("Endpoint parameter with id '\(endpointParam.id)' matched multiple times in remote handler invocation")
                }
                return HandlerInvocationParameter(
                    stableIdentity: endpointParam.lk_stableIdentity,
                    name: endpointParam.name,
                    value: collectedParam.value as! Codable, // TODO this needs to match the constraint used by AnyEndpointParameter!
                    restParameterType: {
                        switch endpointParam.parameterType {
                        case .lightweight:
                            return .query
                        case .content:
                            return .body
                        case .path:
                            return .path
                        }
                    }()
                )
            }
            let missingParamNames: [String] = targetEndpoint.parameters
                .filter { !$0.hasDefaultValue && !alreadyProcessedEndpointParamIds.contains($0.id) }
                .map(\.name)
            guard missingParamNames.isEmpty else {
                fatalError("Missing parameters in remote handler invocation: \(missingParamNames)")
            }
            
            assert(handlerId == targetEndpoint.identifier)
            
            do {
                let handlerInvocation = HandlerInvocation<H>(handlerId: handlerId, targetNode: targetNode, parameters: invocationParams)
                let runtimeHandlingResult = try runtime.handleRemoteHandlerInvocation(handlerInvocation)
                
//                let runtimeHandlingResult = try runtime.handleRemoteHandlerInvocation(
//                    withId: targetEndpoint.identifier.rawValue,
//                    inTargetNode: targetNode,
//                    responseType: H.Response.Content.self,
//                    parameters: invocationParams
//                )
                switch runtimeHandlingResult {
                case .result(let future):
                    return future
                case .invokeDefault(let url):
                    let requestUrl = url
                        .appendingPathComponent("__apodini")
                        .appendingPathComponent("invoke")
                        .appendingPathComponent(targetEndpoint.identifier.rawValue)
                    return RHIIE.app.vapor.app.client.post(
                        //"http://127.0.0.1:5000/__apodini/invoke/\(targetEndpoint.identifier.rawValue)",
                        Vapor.URI(url: requestUrl),
                        headers: [:],
                        beforeSend: { (clientReq: inout Vapor.ClientRequest) in
                            let input = InternalInvocationResponder<H>.Request(
                                parameters: try invocationParams.map { param -> InternalInvocationResponder<H>.Request.EncodedParameter in
                                    return try .init(
                                        stableIdentity: param.stableIdentity,
                                        value: param.encodeValue(using: JSONEncoder())
                                    )
                                }
                            )
                            try clientReq.content.encode(input, using: JSONEncoder())
                            print("clientReq", clientReq)
                        }
                    )
                    .flatMapThrowing { (response: ClientResponse) -> H.Response.Content in
                        let responseData: Data = try response.content.decode(InternalInvocationResponder<H>.Response.self).responseData
                        return try JSONDecoder().decode(H.Response.Content.self, from: responseData)
                    }
                }
            } catch {
                return eventLoop.makeFailedFuture(error)
            }
            
            
//            return eventLoop.tryFuture {
//                return try runtime.invokeRemoteHandler(
//                    withId: targetEndpoint.identifier.rawValue,
//                    inTargetNode: targetNode,
//                    responseType: H.Response.Content.self,
//                    parameters: invocationParams
//                )
//            }.flatMap { $0 }
        }
    }
    
    
    private enum DispatchStrategy {
        case locally
        case remotely(DeployedSystemStructure.Node)
    }
    
    
    private func dispatchStrategy<IH: InvocableHandler>(forInvocationOf endpoint: Endpoint<IH>, RHIIE: ApodiniDeployInterfaceExporter) -> DispatchStrategy {
        guard let runtime = RHIIE.deploymentProviderRuntime else {
            // If there's no runtime registered, we wouldn't be able to dispatch the invocation anyway
            return .locally
        }
        let handlerId = endpoint.identifier
        if let targetNode = runtime.deployedSystem.nodeExportingEndpoint(withHandlerId: handlerId) {
            let currentNode = runtime.deployedSystem.node(withId: runtime.currentNodeId)!
            return targetNode == currentNode ? .locally : .remotely(targetNode)
        }
        print("[Error] Falling back to local dispatch because we were unable to find a node for the endpoint with handler id '\(handlerId)'. This should not be happening.")
        return .locally  // use local dispatching as fallback in case the other stuff fails for some reason
    }
}


extension Endpoint {
    func _invoke(
        withCollectedParameters parameters: [CollectedParameter<H>],
        RHIIE: ApodiniDeployInterfaceExporter,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<H.Response.Content> {
        _invoke(
            withRequest: ApodiniDeployInterfaceExporter.ExporterRequest(endpoint: self, collectedParameters: parameters),
            RHIIE: RHIIE,
            on: eventLoop
        )
    }
    
    
    func _invoke(
        withRequest request: ApodiniDeployInterfaceExporter.ExporterRequest,
        RHIIE: ApodiniDeployInterfaceExporter,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<H.Response.Content> {
        let context = self.createConnectionContext(for: RHIIE)
        let responseFuture: EventLoopFuture<Apodini.Response<EnrichedContent>> = context.handle(request: request, eventLoop: eventLoop)
        return responseFuture.flatMapThrowing { (response: Apodini.Response<EnrichedContent>) -> H.Response.Content in
            guard response.connectionEffect == .close else {
                throw makeApodiniError("Unexpected response value: \(response). Expected '.final'.")
            }
            guard let content = response.content else {
                throw makeApodiniError("Unable to get response content")
            }
            if let value = content.typed(H.Response.Content.self) {
                return value
            } else {
                throw makeApodiniError("Unable to convert response to expected type '\(H.Response.Content.self)'")
            }
        }
    }
}


extension Vapor.URI {
    init(url: URL) {
        self = Vapor.URI(scheme: url.scheme, host: url.host, port: url.port, path: url.path, query: url.query, fragment: url.fragment)
    }
}





// MARK: Environment

extension Apodini.Application {
    public var RHI: RemoteHandlerInvocationManager {
        RemoteHandlerInvocationManager(app: self)
    }
}




extension Handler where Self: WithEventLoop {
    // TODO what about moving the `invoke` functions from the RemoteHandlerInvocationManager?
    // There's really no point in having this type, since, essentially, all it does it store the app/eventLoop object
//    public func invoke
}


