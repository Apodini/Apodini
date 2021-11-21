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

/// An `IntefaceExporter`that writes information from the `Blackboard` to the `Environment` of the delegating `Handler`
public final class ObserveMetadataExporter: InterfaceExporter, TruthAnchor {
    /// Contains all the necessary information from the `Blackboard`, then accessed via the `Environment` property wrapper within a delegating `Handler`
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
            let communicationalPattern: CommunicationalPattern
        }
        
        public var value: BlackboardObserveMetadata
    }
    
    let app: Apodini.Application
    let exporterConfiguration: Configuration
    
    /// Internal initializer for the exporter
    /// - Parameters:
    ///   - app: The Apodini `Application`
    ///   - exporterConfiguration: The appropriate exporter configuration
    init(_ app: Apodini.Application,
         _ exporterConfiguration: Configuration) {
        self.app = app
        self.exporterConfiguration = exporterConfiguration
    }
    
    public func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
        self.exportOntoBlackboard(endpoint)
    }
    
    public func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
        self.exportOntoBlackboard(endpoint)
    }
    
    /// Writes information from the `Blackboard` into the `Envionment` of the `Delegate` so it is accessible from a delegating `Handler` via the `Envionment` property wrapper
    private func exportOntoBlackboard<H>(_ endpoint: Endpoint<H>) where H: Handler {
        let delegate = endpoint[DelegateFactoryBasis<H>.self].delegate
        
        delegate.environment(
            \BlackboardObserveMetadata.value,
            BlackboardObserveMetadata.BlackboardObserveMetadata(
                endpointName: Self.extractRawEndpointName(endpoint.description),
                endpointParameters: endpoint[EndpointParameters.self],
                parameters: endpoint[All<ParameterRetriever>.self].elements,
                operation: endpoint[Operation.self],
                endpointPathComponents: endpoint[EndpointPathComponents.self],
                context: endpoint[Context.self],
                anyEndpointSource: endpoint[AnyEndpointSource.self],
                handleReturnType: endpoint[HandleReturnType.self],
                responseType: endpoint[ResponseType.self],
                communicationalPattern: endpoint[CommunicationalPattern.self]
            )
        )
    }
    
    /// Extract the raw name from the endpoint from a generic type string
    /// - Parameter endpointName: String containing the generic type string
    /// - Returns: Raw name of the endpoint
    static func extractRawEndpointName(_ endpointName: String) -> String {
        guard let splitted = endpointName.components(separatedBy: "<").last,
              let rawEndpointName = splitted.split(separator: ",").first else {
                  return endpointName
              }
        
        return String(rawEndpointName)
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
