//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniLoggingSupport
import Logging

@propertyWrapper
public struct LoggingMetadata: DynamicProperty {
    /// The ``Connection`` of the associated handler
    /// The actual ``Request`` resides here
    @Environment(\.connection)
    private var connection: Connection
    
    /// Metadata from ``BlackBoard`` and data regarding the ``Exporter`` that is injected into the environment of the ``Handler``
    @ObserveMetadata
    private var observeMetadata
    
    @State
    private var builtMetadata: Logger.Metadata = [:]
    
    public var wrappedValue: Logger.Metadata {
        if builtMetadata.isEmpty {
            let request = connection.request
            
            // Write connection metadata
            builtMetadata["connection"] = .dictionary(self.connectionMetadata)
            
            // Write request metadata
            builtMetadata["request"] = .dictionary(self.getRequestMetadata(from: request)
                                                                .merging(self.getRawRequestMetadata(from: connection.information)) { _, new in new })
            
            // Write information metadata
            builtMetadata["information"] = .dictionary(self.getInformationMetadata(from: connection.information))
            
            // Write endpoint metadata
            builtMetadata["endpoint"] = .dictionary(self.endpointMetadata)
            
            // Write exporter metadata
            builtMetadata["exporter"] = .dictionary(self.exporterMetadata)
        } else {
            // Connection stays open since these communicational patterns allow for any amount of client messages
            // Therfore the metadata chould have changed and we need to reevaluate it
            switch self.observeMetadata.0.communicationalPattern {
            case .clientSideStream, .bidirectionalStream:
                // Write connection metadata
                builtMetadata["connection"] = .dictionary(self.connectionMetadata)
                
                // Write request metadata
                builtMetadata["request"] = .dictionary(self.getRequestMetadata(from: connection.request)
                                                                    .merging(
                                                                        self.getRawRequestMetadata(from: connection.information)
                                                                    ) { _, new in new })
            default: break
            }
        }
        
        return builtMetadata
    }
    
    public init() {}
}

private extension LoggingMetadata {
    private var endpointMetadata: Logger.Metadata {
        [
            "name": .string(self.observeMetadata.0.endpointName),
            "parameters": .array(self.observeMetadata.0.endpointParameters.map { parameter in
                    .string(parameter.debugDescription)
            }),
            "operation": .string(self.observeMetadata.0.operation.description),
            "endpointPath": .string(self.observeMetadata.0.endpointPathComponents.value.reduce(into: "", { partialResult, endpointPath in
                partialResult.append(contentsOf: endpointPath.description)
            })),
            "version": .string(self.observeMetadata.0.context.get(valueFor: APIVersionContextKey.self)?.debugDescription ?? "unknown"),
            "handlerType": .string(String(describing: self.observeMetadata.0.anyEndpointSource.handlerType)),
            "handlerReturnType": .string(String(describing: self.observeMetadata.0.handleReturnType.type)),
            "serviceType": .string(self.observeMetadata.0.serviceType.rawValue),
            "communicationalPattern": .string(self.observeMetadata.0.communicationalPattern.rawValue)
        ]
    }
    
    private var exporterMetadata: Logger.Metadata {
        [
            "type": .string(String(describing: self.observeMetadata.1.exporterType)),
            "parameterNamespace": .array(self.observeMetadata.1.parameterNamespace.map { .string($0.description) })
        ]
    }
    
    private var connectionMetadata: Logger.Metadata {
        [
            "remoteAddress": .string(self.connection.remoteAddress?.description ?? "unknown"),
            "state": .string(connection.state.rawValue),
            "eventLoop": .string(self.connection.eventLoop.description)
        ]
    }
    
    private func getInformationMetadata(from informationSet: InformationSet) -> Logger.Metadata {
        informationSet.reduce(into: [:]) { partialResult, info in
            if let stringKeyedStringInformation = info as? StringKeyedStringInformationClass,
                   !stringKeyedStringInformation.sensitive {
                partialResult[stringKeyedStringInformation.entry.key] = .string(stringKeyedStringInformation.entry.value)
            }
        }
    }
    
    private func getRawRequestMetadata(from informationSet: InformationSet) -> Logger.Metadata {
        informationSet.reduce(into: [:]) { partialResult, info in
            if let loggingMetadataInformation = info as? LoggingMetadataInformationClass,
                   !loggingMetadataInformation.sensitive {
                partialResult[loggingMetadataInformation.entry.key] = loggingMetadataInformation.entry.value as? Logger.MetadataValue
            }
        }
    }
    
    private func getRequestMetadata(from request: Request) -> Logger.Metadata {
        var builtRequestMetadata: Logger.Metadata = [:]
        
        // Limit size since eg. the description of the WebSocket exporter contains the request parameters
        builtRequestMetadata["description"] = .string(request.description.count < 32_768 ? request.description : "\(request.description.prefix(32_715))... (further bytes omitted since description too large!")
        builtRequestMetadata["debugDescription"] = .string(request.debugDescription.count < 32_768 ? request.debugDescription : "\(request.debugDescription.prefix(32_715))... (further bytes omitted since description too large!")
        
        let parameterMetadata = self.observeMetadata.0.parameters.reduce(into: Logger.Metadata(), { partialResult, parameter in
            if let typeErasedParameter = try? parameter.1.retrieveParameter(from: connection.request) {
                partialResult[String(parameter.0.dropFirst())] = Self.convertToMetadata(parameter: typeErasedParameter.wrappedValue)
            } else {
                partialResult[String(parameter.0.dropFirst())] = .string("nil")
            }
        })
        
        builtRequestMetadata["parameters"] = .dictionary(parameterMetadata)
        
        return builtRequestMetadata
    }
}

private extension LoggingMetadata {
    /// Converts a ``Codable`` parameter to ``Logger.MetadataValue``
    private static func convertToMetadata(parameter: Encodable) -> Logger.MetadataValue {
        do {
            let encodedParameter = try parameter.encodeToJSON()
            
            // If parameter is too large, cut if after 8kb
            if encodedParameter.count > 8_192 {
                return .string("\(encodedParameter.description.prefix(8_100))... (Further bytes omitted since parameter too large!)")
            }
            
            return try Logger.MetadataValue.convertToMetadata(data: encodedParameter)
        } catch {
            return .string("Error during encoding of a parameter to Logger.MetadataValue - \(error)")
        }
    }
}
