//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
// 

import Apodini
import ApodiniExtension
import ApodiniUtils

/// An ``IntefaceExporter``that writes information from the ``Blackboard`` to the ``Environment`` of the ``Delegate``
public final class ObserveMetadataExporter: InterfaceExporter, TruthAnchor {
    /// Contains all the necessary information from the ``Blackboard``, then accessed via the ``Environment`` property wrapper of the ``ApodiniLogger``
    public struct BlackboardObserveMetadata: EnvironmentAccessible {
        public struct BlackboardObserveMetadata {
            let endpointName: String
            let endpointParameters: EndpointParameters
            let parameters: [(String, ParameterRetriever)]
            let operation: Apodini.Operation
            let endpointPathComponents: EndpointPathComponents
            let context: Context
            let anyEndpointSource: AnyEndpointSource
            let handleReturnType: HandleReturnType
            let responseType: ResponseType
            let serviceType: ServiceType
            let communicationalPattern: CommunicationalPattern
        }
        
        public var value: BlackboardObserveMetadata
    }
    
    let app: Apodini.Application
    let exporterConfiguration: LoggerConfiguration
    
    init(_ app: Apodini.Application,
         _ exporterConfiguration: LoggerConfiguration) {
        self.app = app
        self.exporterConfiguration = exporterConfiguration
    }
    
    public func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
        self.exportOntoBlackboard(endpoint)
    }
    
    public func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        self.exportOntoBlackboard(endpoint)
    }
    
    /// Writes information from the ``Blackboard`` into the ``Envionment`` of the ``Delegate`` so it is accessible from the ``ApodiniLogger`` via the ``Envionment`` property wrapper
    private func exportOntoBlackboard<H>(_ endpoint: Endpoint<H>) where H: Handler {
        let delegate = endpoint[DelegateFactoryBasis<H>.self].delegate
        
        // Information which is required for the LoggingMetadata of the ApodiniLogger
        let blackboardMetadata = BlackboardObserveMetadata.BlackboardObserveMetadata(
            endpointName: endpoint.description,
            endpointParameters: endpoint[EndpointParameters.self],
            parameters: endpoint[All<ParameterRetriever>.self].elements,
            operation: endpoint[Operation.self],
            endpointPathComponents: endpoint[EndpointPathComponents.self],
            context: endpoint[Context.self],
            anyEndpointSource: endpoint[AnyEndpointSource.self],
            handleReturnType: endpoint[HandleReturnType.self],
            responseType: endpoint[ResponseType.self],
            serviceType: endpoint[ServiceType.self],
            communicationalPattern: endpoint[CommunicationalPattern.self]
        )
        
        delegate.environment(\BlackboardObserveMetadata.value, blackboardMetadata)
    }
}

// MARK: ParameterRetriever

/// A type-erased protocol implemented by `Parameter`. It allows ``ApodiniLogger`` to
/// access input-values from a `Request` in an untyped manner.
protocol ParameterRetriever {
    func retrieveParameter(from request: Request) throws -> AnyEncodable
}

extension Parameter: ParameterRetriever {
    func retrieveParameter(from request: Request) throws -> AnyEncodable {
        AnyEncodable(try request.retrieveParameter(self))
    }
}
