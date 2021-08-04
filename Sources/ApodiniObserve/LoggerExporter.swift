//
//  LoggerExporter.swift
//
//  Created by Philipp Zagar on 01.08.21.
//

import Foundation
import Logging
import Apodini
import ApodiniExtension
import ApodiniUtils

/// An ``IntefaceExporter``that writes information from the ``Blackboard`` to the ``Environment`` of the ``Delegate``
public final class LoggerExporter: InterfaceExporter, TruthAnchor {
    /// Contains all the necessary information from the ``Blackboard``, then accessed via the ``Environment`` property wrapper of the ``ConfiguredLogger``
    public struct BlackboardMetadata: EnvironmentAccessible {
        public struct BlackboardMetadata {
            public let endpointName: String
            public let endpointParameters: EndpointParameters
            let parameters: [ParameterRetriever]
            public let operation: Apodini.Operation
            public let endpointPathComponents: EndpointPathComponents
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
    
    public func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
        self.exportOntoBlackboard(endpoint)
    }
    
    public func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        self.exportOntoBlackboard(endpoint)
    }
    
    /// Writes information from the ``Blackboard`` into the ``Envionment`` of the ``Delegate`` so it is accessible from the ``ConfiguredLogger`` via the ``Envionment`` property wrapper
    private func exportOntoBlackboard<H>(_ endpoint: Endpoint<H>) where H: Handler {
        let delegate = endpoint[DelegateFactoryBasis<H>.self].delegate
        
        // Information which is required for the LoggingMetadata of the ConfiguredLogger
        let blackboardMetadata = BlackboardMetadata.BlackboardMetadata(
            endpointName: endpoint.description,
            endpointParameters: endpoint[EndpointParameters.self],
            parameters: endpoint[All<ParameterRetriever>.self].elements.map { $0.1 },
            operation: endpoint[Operation.self],
            endpointPathComponents: endpoint[EndpointPathComponents.self],
            context: endpoint[Context.self],
            anyEndpointSource: endpoint[AnyEndpointSource.self],
            handleReturnType: endpoint[HandleReturnType.self],
            responseType: endpoint[ResponseType.self],
            serviceType: endpoint[ServiceType.self]
        )
        
        delegate.environment(\BlackboardMetadata.value, blackboardMetadata)
    }
}

// MARK: ParameterRetriever

/// A type-erased protocol implemented by `Parameter`. It allows ``ConfiguredLogger`` to
/// access input-values from a `Request` in an untyped manner.
protocol ParameterRetriever {
    func retrieveParameter(from request: Request) throws -> AnyEncodable
}

extension Parameter: ParameterRetriever {
    func retrieveParameter(from request: Request) throws -> AnyEncodable {
        AnyEncodable(try request.retrieveParameter(self))
    }
}
