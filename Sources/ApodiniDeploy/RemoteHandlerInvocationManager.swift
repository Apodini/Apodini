//
//  RemoteHandlerInvocationManager.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-14.
//

import Foundation
import NIO
import Apodini
import ApodiniUtils
import ApodiniDeployBuildSupport
import ApodiniDeployRuntimeSupport
import ApodiniVaporSupport
@_implementationOnly import Vapor


/// Helper type which stores an argument for a remote handler invocation.
public struct CollectedArgument<HandlerType: Handler> {
    /// The (partially type-erased) key path into the handler, to the `Parameter<>.ID` object of the `@Parameter` this value references
    let handlerKeyPath: PartialKeyPath<HandlerType>
    
    /// The argument value
    let value: Any
    
    /// Type-safe way to define an argument passed to a remote invocation
    public init<Value>(_ keyPathIntoHandler: KeyPath<HandlerType, Binding<Value>>, _ value: Value) where HandlerType: InvocableHandler {
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
    /// - parameter arguments: The arguments to be passed to to the invoked handler
    public func invoke<H: InvocableHandler>(
        _ handlerType: H.Type,
        identifiedBy handlerId: H.HandlerIdentifier,
        arguments: H.ArgumentsStorage
    ) -> EventLoopFuture<H.Response.Content> {
        invokeImp(
            handlerType: H.self,
            handlerId: handlerId,
            collectedInputArgs: H.ArgumentsStorage.mapping.map { mappingEntry in
                CollectedArgument<H>(
                    handlerKeyPath: mappingEntry.handlerKeyPath,
                    value: arguments[keyPath: mappingEntry.argsStructKeyPath]
                )
            }
        )
    }
    
    // If the type doesn't specify a `Parameters` struct (ie, H.Arguments still is the _NoArguments default type),
    // we enable the `CollectedArgument` API.
    // This means that the developer of a Handler can force the user of the -invoke API to use the handler-provided Params type,
    // and that using the (somewhat worse, because unable to compile-time-check completion) collected params api isn't available.
    /// Invoke an invocable handler from within your handler.
    /// - parameter handlerType: The static type of the `InvocableHandler` you wish to invoke
    /// - parameter handlerId: The identifier of the to-be-invoked handler. This is required to locate the handler within the web service.
    /// - parameter arguments: The arguments to be passed to to the invoked handler
    public func invoke<H: InvocableHandler>(
        _ handlerType: H.Type,
        identifiedBy handlerId: H.HandlerIdentifier,
        arguments: [CollectedArgument<H>] = []
    ) -> EventLoopFuture<H.Response.Content> where H.ArgumentsStorage == InvocableHandlerEmptyArgumentsStorage<H> {
        invokeImp(handlerType: handlerType, handlerId: handlerId, collectedInputArgs: arguments)
    }
    
    
    struct RemoteInvocationResponseError: Swift.Error {
        enum Context {
            // The error was caused by the invoked handler
            case handlerError
            // The invoked handler ran without errors,
            // but there was an error encoding the handler's response
            case internalError
        }
        let context: Context
        let recordedErrorMessage: String
    }
    
    
    private func invokeImp<H: InvocableHandler>(
        handlerType: H.Type,
        handlerId: H.HandlerIdentifier,
        collectedInputArgs: [CollectedArgument<H>]
    ) -> EventLoopFuture<H.Response.Content> {
        guard let internalInterfaceExporter = self.app.storage.get(ApodiniDeployInterfaceExporter.ApplicationStorageKey.self) else {
            return eventLoop.makeFailedFuture(ApodiniDeployError(message: "Unable to get \(ApodiniDeployInterfaceExporter.self) object"))
        }
        
        guard let targetEndpoint: Endpoint<H> = internalInterfaceExporter.getEndpoint(withIdentifier: handlerId, ofType: H.self) else {
            return eventLoop.makeFailedFuture(ApodiniDeployError(message: "Unable to find target endpoint. (handlerId: '\(handlerId)', handlerType: '\(H.self)')"))
        }
        
        switch dispatchStrategy(forInvocationOf: targetEndpoint, internalInterfaceExporter: internalInterfaceExporter) {
        case .locally:
            return targetEndpoint.invokeImp(
                withCollectedArguments: collectedInputArgs,
                internalInterfaceExporter: internalInterfaceExporter,
                on: eventLoop
            )
        case .remotely(let targetNode):
            return invokeRemotely(
                handlerId: handlerId,
                internalInterfaceExporter: internalInterfaceExporter,
                targetNode: targetNode,
                targetEndpoint: targetEndpoint,
                collectedInputArgs: collectedInputArgs
            )
        }
    }
    
    
    /// Remotely invoke a specific endpoint, in a specific node of the deployed system
    private func invokeRemotely<H: InvocableHandler>( // swiftlint:disable:this function_body_length cyclomatic_complexity
        handlerId: H.HandlerIdentifier,
        internalInterfaceExporter: ApodiniDeployInterfaceExporter,
        targetNode: DeployedSystem.Node,
        targetEndpoint: Endpoint<H>,
        collectedInputArgs: [CollectedArgument<H>]
    ) -> EventLoopFuture<H.Response.Content> {
        guard let runtime = internalInterfaceExporter.deploymentProviderRuntime else {
            return eventLoop.makeFailedFuture(ApodiniDeployError(message: "Unable to find runtime"))
        }
        // The targetEndpoint is on a different node, dispatch the invocation there
        
        // Note that if theres a guarantee that an EndpointParameter's id is the same as the id of the @Parameter it was generated from,
        // we can combine these two sets into one
        var alreadyProcessedParamKeyPaths: Set<AnyKeyPath> = []
        var alreadyProcessedEndpointParamIds: Set<UUID> = []

        let invocationParams: [HandlerInvocation<H>.Parameter] = collectedInputArgs.map { collectedArg in
            // The @Parameter property wrapper declaration in the handler
            guard
                let handlerParamId = Apodini.Internal.getParameterId(ofBinding: targetEndpoint.handler[keyPath: collectedArg.handlerKeyPath])
            else {
                fatalError("Unable to get @Parameter id for collected parameter with key path \(collectedArg.handlerKeyPath)")
            }
            guard let endpointParam: AnyEndpointParameter = targetEndpoint.findParameter(for: handlerParamId) else {
                fatalError("Unable to fetch endpoint parameter for handlerParamId '\(handlerParamId)'")
            }
            if !alreadyProcessedParamKeyPaths.insert(collectedArg.handlerKeyPath).inserted {
                app.logger.warning("Parameter '\(endpointParam.name)' specified multiple times in remote handler invocation")
            }
            if !alreadyProcessedEndpointParamIds.insert(endpointParam.id).inserted {
                app.logger.warning("Endpoint parameter with id '\(endpointParam.id)' matched multiple times in remote handler invocation")
            }
            return HandlerInvocation<H>.Parameter(
                stableIdentity: endpointParam.stableIdentity,
                name: endpointParam.name,
                value: unsafelyCast(collectedArg.value, to: HandlerInvocation<H>.Parameter.Value.self)
            )
        }
        let missingParamNames: [String] = targetEndpoint.parameters
            .filter { !$0.hasDefaultValue && !alreadyProcessedEndpointParamIds.contains($0.id) }
            .map(\.name)
        guard missingParamNames.isEmpty else {
            fatalError("Missing parameters in remote handler invocation: \(missingParamNames)")
        }
        
        assert(handlerId == targetEndpoint[AnyHandlerIdentifier.self])
        
        do {
            let handlerInvocation = HandlerInvocation<H>(handlerId: handlerId, targetNode: targetNode, parameters: invocationParams)
            let runtimeHandlingResult = try runtime.handleRemoteHandlerInvocation(handlerInvocation)
            
            switch runtimeHandlingResult {
            case .result(let future):
                return future
            
            case .invokeDefault(let url):
                let requestUrl = url
                    .appendingPathComponent("__apodini")
                    .appendingPathComponent("invoke")
                    .appendingPathComponent(targetEndpoint[AnyHandlerIdentifier.self].rawValue)
                return internalInterfaceExporter.vaporApp.client.post(
                    Vapor.URI(url: requestUrl),
                    headers: [:],
                    beforeSend: { (clientReq: inout Vapor.ClientRequest) in
                        let input = InternalInvocationResponder<H>.Request(
                            parameters: try invocationParams.map { param -> InternalInvocationResponder<H>.Request.EncodedParameter in
                                try .init(
                                    stableIdentity: param.stableIdentity,
                                    encodedValue: param.encodeValue(using: JSONEncoder())
                                )
                            }
                        )
                        try clientReq.content.encode(input, using: JSONEncoder())
                    }
                )
                .flatMapThrowing { (clientResponse: ClientResponse) -> H.Response.Content in
                    let handlerResponse = try clientResponse.content.decode(InternalInvocationResponder<H>.Response.self)
                    switch handlerResponse.status {
                    case .success:
                        return try JSONDecoder().decode(H.Response.Content.self, from: handlerResponse.encodedData)
                    case .handlerError, .internalError:
                        throw RemoteInvocationResponseError(
                            context: handlerResponse.status == .handlerError ? .handlerError : .internalError,
                            recordedErrorMessage: try JSONDecoder().decode(String.self, from: handlerResponse.encodedData)
                        )
                    }
                }
            }
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }
    
    
    private enum DispatchStrategy {
        case locally
        case remotely(DeployedSystem.Node)
    }
    
    
    private func dispatchStrategy<IH: InvocableHandler>(
        forInvocationOf endpoint: Endpoint<IH>,
        internalInterfaceExporter: ApodiniDeployInterfaceExporter
    ) -> DispatchStrategy {
        guard let runtime = internalInterfaceExporter.deploymentProviderRuntime else {
            // If there's no runtime registered, we wouldn't be able to dispatch the invocation anyway
            return .locally
        }
        let handlerId = endpoint[AnyHandlerIdentifier.self]
        if let targetNode = runtime.deployedSystem.nodeExportingEndpoint(withHandlerId: handlerId) {
            guard let currentNode = runtime.deployedSystem.node(withId: runtime.currentNodeId) else {
                fatalError("Unable to find current node")
            }
            return targetNode == currentNode ? .locally : .remotely(targetNode)
        }
        app.logger.error("Falling back to local dispatch because we were unable to find a node for the endpoint with handler id '\(handlerId)'. This should not be happening.")
        return .locally  // use local dispatching as fallback in case the other stuff fails for some reason
    }
}


extension Endpoint {
    func invokeImp(
        withCollectedArguments arguments: [CollectedArgument<H>],
        internalInterfaceExporter: ApodiniDeployInterfaceExporter,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<H.Response.Content> {
        invokeImp(
            withRequest: ApodiniDeployInterfaceExporter.ExporterRequest(endpoint: self, collectedArguments: arguments),
            internalInterfaceExporter: internalInterfaceExporter,
            on: eventLoop
        )
    }
    
    
    func invokeImp(
        withRequest request: ApodiniDeployInterfaceExporter.ExporterRequest,
        internalInterfaceExporter: ApodiniDeployInterfaceExporter,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<H.Response.Content> {
        let context = self.createConnectionContext(for: internalInterfaceExporter)
        let responseFuture: EventLoopFuture<Apodini.Response<H.Response.Content>> = context.handle(request: request, eventLoop: eventLoop)
        return responseFuture.flatMapThrowing { (response: Apodini.Response<H.Response.Content>) -> H.Response.Content in
            guard response.connectionEffect == .close else {
                throw ApodiniDeployError(message: "Unexpected response value: \(response). Expected '.final'.")
            }
            guard let content = response.content else {
                throw ApodiniDeployError(message: "Unable to get response content")
            }
            return content
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
    /// A remote handler invocation manager object, which can be used to invoke other handlers from within a handler's `handle` function.
    public var RHI: RemoteHandlerInvocationManager {
        RemoteHandlerInvocationManager(app: self)
    }
}
