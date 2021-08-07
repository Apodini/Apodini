//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
// 

import Logging
import Apodini

/// A ``Configuration`` for the ``Logger``.
public final class LoggerConfiguration: Configuration {
    /// The storage key for Logging-related information.
    public struct LoggingStorageKey: StorageKey {
        public typealias Value = LoggingStorageValue
    }

    /// The enclosing storage entity for OpenAPI-related information.
    /// Commented out conformance to EnvironmentAccessible since the config is accessed via the storage
    public struct LoggingStorageValue {
        /// The application `Logger`
        public let logger: Logger
        /// The configuration used by `Logger` instances
        public let configuration: LoggerConfiguration
        
        internal init(logger: Logger, configuration: LoggerConfiguration) {
            self.logger = logger
            self.configuration = configuration
        }
    }
    
    internal let logLevel: Logger.Level
    internal let logHandlers: [LogHandler]
    
    /// initalize `LoggerConfiguration` with the `logLevel` and the to be used backend `logHandlers`
    public init(logLevel: Logger.Level, logHandlers: LogHandler...) {
        self.logLevel = logLevel
        self.logHandlers = logHandlers
    }
    
    /// Configure application
    public func configure(_ app: Application) {
        // Instanciate exporter
        let loggerExporter = LoggerExporter(app, self)
        
        // Insert exporter into `InterfaceExporterStorage`
        app.registerExporter(exporter: loggerExporter)
        
        // Write configuration to the storage
        app.storage.set(LoggingStorageKey.self, to: LoggingStorageValue(logger: app.logger, configuration: self))
        
        // Bootstrap the logging system
        LoggingSystem.bootstrap { _ in
            MultiplexLogHandler(
                self.logHandlers
            )
        }
    }
}
