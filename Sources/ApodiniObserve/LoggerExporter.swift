//
//  LoggerExporter.swift
//
//  Created by Philipp Zagar on 01.08.21.
//

import Foundation
import Logging
import Apodini
import ApodiniExtension

/// An ``IntefaceExporter``that writes information from the ``Blackboard`` to the ``Environment`` of the ``Delegate``
public final class LoggerExporter: InterfaceExporter, TruthAnchor {
    /// Contains all the necessary information from the ``Blackboard``, then accessed via the ``Environment`` property wrapper of the ``ConfiguredLogger``
    public struct BlackboardMetadata: EnvironmentAccessible {
        public struct BlackboardMetadata {
            public let endpointName: String
            public let endpointParameters: EndpointParameters
            public let endpointParametersOther: EndpointParameters
            public let endpointParametersById: EndpointParametersById
            public let operation: Apodini.Operation
            public let absolutePath: [EndpointPath]
            public let endpointPathComponents: EndpointPathComponents
            public let endpointPathComponentsHTTP: EndpointPathComponentsHTTP
            public let context: Context
            public let anyEndpointSource: AnyEndpointSource
            public let handleReturnType: HandleReturnType
            public let responseType: ResponseType
            public let serviceType: ServiceType
        }
        
        public var value: BlackboardMetadata
    }
    
    // Not sure if those are maybe needed?
    let app: Apodini.Application
    let exporterConfiguration: LoggerConfiguration
    
    init(_ app: Apodini.Application,
         _ exporterConfiguration: LoggerConfiguration) {
        self.app = app
        self.exporterConfiguration = exporterConfiguration
    }
    
    public func export<H>(_ endpoint: Endpoint<H>) -> () where H : Handler {
        self.exportOntoBlackboard(endpoint)
    }
    
    public func export<H>(blob endpoint: Endpoint<H>) -> () where H : Handler, H.Response.Content == Blob {
        self.exportOntoBlackboard(endpoint)
    }
    
    /// Writes information from the ``Blackboard`` into the ``Envionment`` of the ``Delegate`` so it is accessible from the ``ConfiguredLogger`` via the ``Envionment`` property wrapper
    private func exportOntoBlackboard<H>(_ endpoint: Endpoint<H>) -> () where H: Handler {
        let delegate = endpoint[DelegateFactoryBasis<H>.self].delegate
        
        // Information which is required for the LoggingMetadata of the ConfiguredLogger
        let blackboardMetadata = BlackboardMetadata.BlackboardMetadata(
            endpointName: endpoint.description,
            endpointParameters: endpoint[EndpointParameters.self],
            endpointParametersOther: endpoint.parameters,
            endpointParametersById: endpoint[EndpointParametersById.self],
            operation: endpoint[Operation.self],
            absolutePath: endpoint.absolutePath,
            endpointPathComponents: endpoint[EndpointPathComponents.self],
            endpointPathComponentsHTTP: endpoint[EndpointPathComponentsHTTP.self],
            context: endpoint[Context.self],
            anyEndpointSource: endpoint[AnyEndpointSource.self],
            handleReturnType: endpoint[HandleReturnType.self],
            responseType: endpoint[ResponseType.self],
            serviceType: endpoint[ServiceType.self]
        )
        
        delegate.environment(\BlackboardMetadata.value, blackboardMetadata)
    }
}
