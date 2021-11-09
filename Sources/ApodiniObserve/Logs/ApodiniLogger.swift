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

/// A `DynamicProperty` that allows logging of an associated `Handler`
/// Can be configured with a certain logLevel, so what messages should actually be logged and which shouldn't
/// Automatically attaches metadata from the handler to the built logger so the developer gets easy insights into the system
@propertyWrapper
public struct ApodiniLogger: DynamicProperty {
    /// The `Connection` of the associated handler
    /// The actual `Request` resides here
    @Environment(\.connection)
    private var connection
    
    /// The `Storage` of the `Application`
    @Environment(\.storage)
    private var storage
    
    /// The `Logging.Logger` of the `Application`
    @Environment(\.logger)
    private var logger
    
    /// Aggregated`Logging.Metadata`
    @LoggingMetadata
    var loggingMetadata
    
    /// Raw metadata which can then be aggrgated
    var observeMetadata: ObserveMetadata.Value {
        self._loggingMetadata.observeMetadata
    }
    
    /// Property that holds the built `Logging.Logger` instance
    @State
    private var builtLogger: Logger?
    
    /// A unique ID that identifies the `Logging.Logger` over the lifetime of the associated `Handler`
    private let id: UUID
    /// The logLevel (deciding over what messages should be logged), can be configured via multiple configuration possibilities and prioritizations
    private let logLevel: Logger.Level?
    /// A user-defined label of the built `Logging.Logger`, else a standard default value
    private let label: String?
    /// A user-defined factory for the `Logging.Logger`
    private let logHandler: ((String) -> LogHandler)?
    /// A user-defined level of automatic metadata aggregation
    private let metadataLevel: MetadataLevel
    
    /// Creates a new `@ApodiniLogger`
    public init() {
        self.init(logLevel: nil)
    }
    
    /// Creates a new ``ApodiniLogger`` that can be used as an `DynamicProperty` within a `Handler`
    /// - Parameters:
    ///   - id: A unique identifier of the ``ApodiniLogger``
    ///   - label: A preferably unique label of the ``ApodiniLogger``
    ///   - logLevel: Local `Logger.Level` that overwrites the globally configured log level
    ///   - metadataLevel: The amount of context information automatically attached to log entries created with the ``ApodiniLogger``
    ///   - logHandler: Local `LogHandler` that overwrites the globally configured `LogHandler`
    public init(id: UUID = UUID(),
                label: String? = nil,
                logLevel: Logger.Level? = nil,
                metadataLevel: MetadataLevel = .all,
                logHandler: ((String) -> LogHandler)? = nil) {
        self.id = id
        self.logLevel = logLevel
        self.label = label
        self.metadataLevel = metadataLevel
        self.logHandler = logHandler
    }
    
    /// Represents the built `Logging.Logger` with already attached context information
    public var wrappedValue: Logger {
        let observeMetadata = self.observeMetadata
        
        if builtLogger == nil {
            var label: String
            if let customLabel = self.label {
                // User-defined label of logger
                label = "org.apodini.observe.\(customLabel)"
            } else {
                // Automatically created label in the form of org.apodini.observe.<Handler>.<Exporter>
                label = "org.apodini.observe.\(observeMetadata.blackboardMetadata.endpointName).\(String(describing: observeMetadata.exporterMetadata.exporterType))"
            }
            
            // If user-defined logging factory (loghandler) is passed
            if let customLogHandler = self.logHandler {
                builtLogger = .init(label: label, factory: customLogHandler)
            } else {
                builtLogger = .init(label: label)
            }
            
            // Stays consitent over the lifetime of the associated handler
            builtLogger?[metadataKey: "logger-uuid"] = .string(self.id.uuidString)
            
            // Insert built metadata into the logger
            loggingMetadata
                // User-defined setting what metadata should be automatically aggregated
                .filter { metadataKey, _ in
                    self.metadataLevel.metadataKeys.contains(metadataKey)
                }
                .forEach { metadataKey, metadataValue in
                    builtLogger?[metadataKey: metadataKey] = metadataValue
                }
            
            /// Prio 1: User specifies a `Logger.LogLevel` in the property wrapper for a specific `Handler`
            if let logLevel = self.logLevel {
                builtLogger?.logLevel = logLevel
                
                // If logging level is configured gloally
                if let globalConfiguredLogLevel = storage.get(LoggerConfiguration.LoggingStorageKey.self)?.configuration.logLevel {
                    if logLevel < globalConfiguredLogLevel {
                        logger.warning("The global configured logging level is \(globalConfiguredLogLevel.rawValue) but Handler \(observeMetadata.blackboardMetadata.endpointName) has logging level \(logLevel.rawValue) which is lower than the configured global logging level")
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
                        logger.warning("The global default logging level is \(globalLogLevel.rawValue) but Handler \(observeMetadata.blackboardMetadata.endpointName) has logging level \(logLevel.rawValue) which is lower than the global default logging level")
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
            switch observeMetadata.blackboardMetadata.communicationalPattern {
            case .clientSideStream, .bidirectionalStream:
                // Refresh metadata
                loggingMetadata
                    // Filter for metadata that could have changed
                    .filter { metadataKey, _ in
                        metadataKey == "connection" || metadataKey == "request"
                    }
                    // User-defined setting what metadata should be automatically aggregated
                    .filter { metadataKey, _ in
                        self.metadataLevel.metadataKeys.contains(metadataKey)
                    }
                    .forEach { metadataKey, metadataValue in
                        builtLogger?[metadataKey: metadataKey] = metadataValue
                    }
            case .serviceSideStream:
                // Refresh metadata
                builtLogger?[metadataKey: "connection"] = loggingMetadata["connection"]
            case .requestResponse:
                break
            }
        }
        
        guard let builtLogger = builtLogger else {
            fatalError("The ApodiniLogger isn't built correctly!")
        }
        
        return builtLogger
    }
}

extension ApodiniLogger {
    /// Indicates the level of automatically attached `Metadata`
    public enum MetadataLevel {
        /// All metadata
        case all
        /// Reduced metadata (so only "request", "endpoint", "exporter")
        case reduced
        /// No metadata at all
        case none
        /// Pass the metadata keys that should be automatically attached
        case custom(metadata: [String])
        
        /// The keys of the context information that should be attached to the logs
        var metadataKeys: [String] {
            switch self {
            case .all:
                return ["connection", "request", "information", "endpoint", "exporter"]
            case .reduced:
                return ["request", "endpoint", "exporter"]
            case .none:
                return []
            case .custom(let customMetadata):
                return customMetadata
            }
        }
    }
}
