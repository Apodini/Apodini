//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
// 

import Foundation
import Logging
import Apodini
import ApodiniExtension
import ApodiniHTTPProtocol

@propertyWrapper
/// A ``DynamicProperty`` that allows logging of an associated handler
/// Can be configured with a certain logLevel, so what messages should actually be logged and which shouldn't
/// Automatically attaches metadata from the handler to the built logger so the developer gets easy insights into the system
public struct ConfiguredLogger: DynamicProperty {
    /// The ``Connection`` of the associated handler
    /// The actual ``Request`` resides here
    @Environment(\.connection)
    var connection: Connection
    
    /// The ``Storage`` of the ``Application``
    @Environment(\.storage)
    var storage: Storage
    
    /// The ``Logger`` of the ``Application``
    @Environment(\.logger)
    var logger: Logger
    
    /// Metadata from the ``Blackboard`` that is injected into the environment of the ``Handler``via a ``Delegate``
    @Environment(\LoggerExporter.BlackboardMetadata.value)
    var blackboardMetadata
    
    /// Metadata regarding the ``Exporter``type
    @Environment(\ExporterTypeMetadata.value)
    var exporterTypeMetadata
    
    /// Property that holds the built ``Logger`` instance
    @State
    private var builtLogger: Logger?
    
    /// A unique ID that identifies the ``Logger`` over the lifetime of the associated ``Handler``
    private let id: UUID
    /// The logLevel (deciding over what messages should be logged), can be configured via multiple configuration possibilities and prioritizations
    private let logLevel: Logger.Level?
    /// A user-defined label of the built ``Logger``, else a standard default value
    private let label: String?
    
    public var wrappedValue: Logger {
        if builtLogger == nil {
            if let label = label {
                // User-defined label of logger
                builtLogger = .init(label: "org.apodini.observe.\(label)")
            } else {
                // org.apodini.observe.<Handler>.<Exporter>
                builtLogger = .init(label: "org.apodini.observe.\(self.blackboardMetadata.endpointName).\(String(describing: self.exporterTypeMetadata.exporterType))")
            }
            
            // Stays consitent over the lifetime of the associated handler
            builtLogger?[metadataKey: "logger-uuid"] = .string(self.id.uuidString)
            
            let request = connection.request
            
            // Write remote address
            builtLogger?[metadataKey: "remoteAddress"] = .string(connection.remoteAddress?.description ?? "unknown")
            
            // Write event loop
            builtLogger?[metadataKey: "connectionEventLoop"] = .string(connection.eventLoop.description)
            
            // Write connection state
            builtLogger?[metadataKey: "connectionState"] = .string(connection.state.rawValue)
            
            // Write information metadata
            builtLogger?[metadataKey: "information"] = .dictionary(self.getInformationMetadata(from: connection.information))
            
            // Write request metadata
            builtLogger?[metadataKey: "request"] = .dictionary(self.getRequestMetadata(from: request)
                                                                .merging(self.getRawRequestMetadata(from: connection.information)) { _, new in new })
            
            // Write endpoint metadata
            builtLogger?[metadataKey: "endpoint"] = .dictionary(self.endpointMetadata)
            
            // Write exporter metadata
            builtLogger?[metadataKey: "exporter"] = .dictionary(self.exporterMetadata)
            
            /// Prio 1: User specifies a `Logger.LogLevel` in the property wrapper for a specific `Handler`
            if let logLevel = self.logLevel {
                builtLogger?.logLevel = logLevel
                
                // If logging level is configured gloally
                if let globalConfiguredLogLevel = storage.get(LoggerConfiguration.LoggingStorageKey.self)?.configuration.logLevel {
                    if logLevel < globalConfiguredLogLevel {
                        logger.warning("The global configured logging level is \(globalConfiguredLogLevel.rawValue) but Handler \(self.blackboardMetadata.endpointName) has logging level \(logLevel.rawValue) which is lower than the configured global logging level")
                    }
                // If logging level is automatically set to a default value
                } else {
                    var globalLogLevel: Logger.Level
                    #if DEBUG
                    globalLogLevel = .debug
                    #else
                    globalLogLevel = .info
                    #endif
                    
                    if logLevel < globalLogLevel {
                        logger.warning("The global default logging level is \(globalLogLevel.rawValue) but Handler \(self.blackboardMetadata.endpointName) has logging level \(logLevel.rawValue) which is lower than the global default logging level")
                    }
                }
            }
            /// Prio 2: User specifies a `Logger.LogLevel`either via a CLI argument or via a `LoggerConfiguration` in the configuration of the `WebService`
            else if let loggingConfiguraiton = storage.get(LoggerConfiguration.LoggingStorageKey.self)?.configuration {
                builtLogger?.logLevel = loggingConfiguraiton.logLevel
            }
            /// Prio 3: No `Logger.LogLevel` specified by user, use defaul value according to environment (debug mode or release mode)
            else {
                #if DEBUG
                builtLogger?.logLevel = .debug
                #else
                builtLogger?.logLevel = .info
                #endif
            }
        } else {
            // Not pretty, but otherwise ApodiniObserve would need to depend on ApodiniWebsocket
            if String(describing: exporterTypeMetadata.exporterType) == "WebSocketInterfaceExporter" {
                // Write connection state
                builtLogger?[metadataKey: "connectionState"] = .string(connection.state.rawValue)
                
                // Write request metadata
                builtLogger?[metadataKey: "request"] = .dictionary(self.getRequestMetadata(from: connection.request))
            }
        }
        
        return builtLogger!
    }
    
    /// Private initializer
    private init(id: UUID, logLevel: Logger.Level? = nil, label: String? = nil) {
        self.id = id
        self.logLevel = logLevel
        self.label = label
    }
    
    /// Creates a new `@ConfiguredLogger` and specifies a `Logger.Level`
    public init(id: UUID = UUID(), logLevel: Logger.Level) {
        self.init(id: id, logLevel: logLevel, label: nil)
    }
    
    /// Creates a new `@ConfiguredLogger` and specifies a `Logger.Level`and a label of the `Logger`
    public init(id: UUID = UUID(), label: String? = nil, logLevel: Logger.Level? = nil) {
        self.init(id: id, logLevel: logLevel, label: label)
    }
}

extension ConfiguredLogger {
    private var endpointMetadata: Logger.Metadata {
        [
            "name": .string(self.blackboardMetadata.endpointName),
            "parameters": .array(self.blackboardMetadata.endpointParameters.map { parameter in
                    .string(parameter.description)
            }),
            "operation": .string(self.blackboardMetadata.operation.description),
            "endpointPath": .string(self.blackboardMetadata.endpointPathComponents.value.reduce(into: "", { partialResult, endpointPath in
                partialResult.append(contentsOf: endpointPath.description)
            })),
            "version": .string(self.blackboardMetadata.context.get(valueFor: APIVersionContextKey.self)?.debugDescription ?? "unknown"),
            "handlerType": .string(String(describing: self.blackboardMetadata.anyEndpointSource.handlerType)),
            "handlerReturnType": .string(String(describing: self.blackboardMetadata.handleReturnType.type)),
            "serviceType": .string(self.blackboardMetadata.serviceType.rawValue)
        ]
    }
    
    private var exporterMetadata: Logger.Metadata {
        [
            "type": .string(String(describing: exporterTypeMetadata.exporterType)),
            "parameterNamespace": .array(exporterTypeMetadata.parameterNamespace.map { .string($0.description) })
        ]
    }
    
    private func getInformationMetadata(from informationSet: InformationSet) -> Logger.Metadata {
        informationSet.reduce(into: [:]) { partialResult, info in
            if let anyHTTPInformation = info as? AnyHTTPInformation {
                if let auth = anyHTTPInformation.typed(Authorization.self) {
                    partialResult[Authorization.header] = .string(auth.type)
                } else if let cookies = anyHTTPInformation.typed(Cookies.self) {
                    partialResult[Cookies.header] = .dictionary(
                        cookies.value.reduce(into: [:]) { partialResult, cookie in
                            partialResult[cookie.key] = .string(cookie.value)
                        }
                    )
                } else if let etag = anyHTTPInformation.typed(ETag.self) {
                    partialResult[ETag.header] = .string(etag.rawValue)
                } else if let expires = anyHTTPInformation.typed(Expires.self) {
                    partialResult[Expires.header] = .string(expires.rawValue)
                } else if let redirectTo = anyHTTPInformation.typed(RedirectTo.self) {
                    partialResult[RedirectTo.header] = .string(redirectTo.rawValue)
                } else {
                    partialResult[anyHTTPInformation.key.key] = .string(anyHTTPInformation.value)
                }
            }
        }
    }
    
    private func getRawRequestMetadata(from informationSet: InformationSet) -> Logger.Metadata {
        informationSet.reduce(into: [:]) { partialResult, info in
            if let metadataInformation = info as? LoggingMetadataInformation {
                partialResult[metadataInformation.key.key] = metadataInformation.metadataValue
            }
        }
    }
    
    private func getRequestMetadata(from request: Request) -> Logger.Metadata {
        var builtRequestMetadata: Logger.Metadata = [:]
        
        // Limit size since eg. the description of the WebSocket exporter contains the request parameters
        builtRequestMetadata["description"] = .string(request.description.count < 32_768 ? request.description : "\(request.description.prefix(32_715))... (further bytes omitted since description too large!")
        builtRequestMetadata["debugDescription"] = .string(request.debugDescription.count < 32_768 ? request.debugDescription : "\(request.debugDescription.prefix(32_715))... (further bytes omitted since description too large!")
        
        let parameterMetadata = blackboardMetadata.parameterTupels.reduce(into: Logger.Metadata(), { partialResult, parameter in
            if let typeErasedParameter = try? parameter.1.retrieveParameter(from: connection.request) {
                partialResult[String(parameter.0.dropFirst())] = Logger.MetadataValue.convertToMetadata(parameter: typeErasedParameter.wrappedValue)
            } else {
                partialResult[String(parameter.0.dropFirst())] = .string("nil")
            }
        })
        
        builtRequestMetadata["parameters"] = .dictionary(parameterMetadata)
        
        return builtRequestMetadata
    }
}
