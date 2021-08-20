//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
// 

import Foundation
import Apodini
import Logging

@propertyWrapper
/// A ``DynamicProperty`` that allows logging of an associated handler
/// Can be configured with a certain logLevel, so what messages should actually be logged and which shouldn't
/// Automatically attaches metadata from the handler to the built logger so the developer gets easy insights into the system
public struct ApodiniLogger: DynamicProperty {
    /// The ``Connection`` of the associated handler
    /// The actual ``Request`` resides here
    @Environment(\.connection)
    private var connection
    
    /// The ``Storage`` of the ``Application``
    @Environment(\.storage)
    private var storage
    
    /// The ``Logger`` of the ``Application``
    @Environment(\.logger)
    private var logger
    
    /// Aggregated``Logging.Metadata``
    @LoggingMetadata
    var loggingMetadata
    
    /// Raw metadata which can then be aggrgated
    var observeMetadata: ObserveMetadata.Value {
        self._loggingMetadata.observeMetadata
    }
    
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
        let observeMetadata = self.observeMetadata
        
        if builtLogger == nil {
            if let label = label {
                // User-defined label of logger
                builtLogger = .init(label: "org.apodini.observe.\(label)")
            } else {
                // org.apodini.observe.<Handler>.<Exporter>
                builtLogger = .init(label: "org.apodini.observe.\(observeMetadata.0.endpointName).\(String(describing: observeMetadata.1.exporterType))")
            }
            
            // Stays consitent over the lifetime of the associated handler
            builtLogger?[metadataKey: "logger-uuid"] = .string(self.id.uuidString)
            
            // Insert built metadata into the logger
            loggingMetadata.forEach { metadataKey, metadataValue in
                builtLogger?[metadataKey: metadataKey] = metadataValue
            }
            
            /// Prio 1: User specifies a `Logger.LogLevel` in the property wrapper for a specific `Handler`
            if let logLevel = self.logLevel {
                builtLogger?.logLevel = logLevel
                
                // If logging level is configured gloally
                if let globalConfiguredLogLevel = storage.get(LoggerConfiguration.LoggingStorageKey.self)?.configuration.logLevel {
                    if logLevel < globalConfiguredLogLevel {
                        logger.warning("The global configured logging level is \(globalConfiguredLogLevel.rawValue) but Handler \(observeMetadata.0.endpointName) has logging level \(logLevel.rawValue) which is lower than the configured global logging level")
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
                        logger.warning("The global default logging level is \(globalLogLevel.rawValue) but Handler \(observeMetadata.0.endpointName) has logging level \(logLevel.rawValue) which is lower than the global default logging level")
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
            // Connection stays open since these communicational patterns allow for any amount of client messages
            switch observeMetadata.0.communicationalPattern {
            case .clientSideStream, .bidirectionalStream:
                // Insert built metadata into the logger
                loggingMetadata
                    // Filter for metadata that could have changed
                    .filter { metadataKey, _ in
                        metadataKey == "connection" || metadataKey == "request"
                    }
                    .forEach { metadataKey, metadataValue in
                        builtLogger?[metadataKey: metadataKey] = metadataValue
                    }
            default: break
            }
        }
        
        guard let builtLogger = builtLogger else {
            fatalError("The ApodiniLogger isn't built correctly!")
        }
        
        return builtLogger
    }
    
    /// Private initializer
    private init(id: UUID, logLevel: Logger.Level? = nil, label: String? = nil) {
        self.id = id
        self.logLevel = logLevel
        self.label = label
    }
    
    /// Creates a new `@ApodiniLogger` and specifies a `Logger.Level`
    public init(id: UUID = UUID(), logLevel: Logger.Level) {
        self.init(id: id, logLevel: logLevel, label: nil)
    }
    
    /// Creates a new `@ApodiniLogger` and specifies a `Logger.Level`and a label of the `Logger`
    public init(id: UUID = UUID(), label: String? = nil, logLevel: Logger.Level? = nil) {
        self.init(id: id, logLevel: logLevel, label: label)
    }
}
