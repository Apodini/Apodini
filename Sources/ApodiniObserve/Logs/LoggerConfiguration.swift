//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
// 

import Logging
import Apodini

/// The `Configuration` for the ``ApodiniLogger``.
public final class LoggerConfiguration: Configuration {
    /// The storage key for Logging-related information.
    public struct LoggingStorageKey: StorageKey {
        public typealias Value = LoggingStorageValue
    }

    /// The value key for Logging-related information.
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
    
    /// The globally configured `Logger.Level`
    let logLevel: Logger.Level
    /// The to be used `LogHandler`'s
    let logHandlers: [(String) -> LogHandler]
    /// The custom configuration closure that can be used by the developer to set up the to be used`LogHandler`'s
    let configureLogHandlers: () -> Void
    
    /// initalize ``LoggerConfiguration`` with the `logLevel` and the to be used backend `LogHandler`'s
    /// - Parameters:
    ///   - logHandlers: Arbitrary number of `LogHandler`s that represent the to be used logging backends
    ///   - logLevel: Specifies the global log level for the ``ApodiniLogger``
    public init(logHandlers: (String) -> LogHandler..., logLevel: Logger.Level) {
        self.logLevel = logLevel
        self.logHandlers = logHandlers
        self.configureLogHandlers = {}
    }
    
    /// initalize ``LoggerConfiguration`` with the `logLevel` and the to be used backend `LogHandler`'s
    /// - Parameters:
    ///   - logHandlers: Arbitrary number of `LogHandler`s that represent the to be used logging backends
    ///   - logLevel: Specifies the global log level for the ``ApodiniLogger``
    ///   - configureLogHandlers: A custom closure that is able to statically set up the to be used `LogHandler`'s
    public init(logHandlers: (String) -> LogHandler..., logLevel: Logger.Level, configureLogHandlers: @escaping () -> Void) {
        self.logLevel = logLevel
        self.logHandlers = logHandlers
        self.configureLogHandlers = configureLogHandlers
    }
    
    /// Configures the `Application`for the ``ApodiniLogger``
    /// - Parameter app: The to be configured `Application`
    public func configure(_ app: Application) {
        // Instanciate exporter
        let loggerExporter = ObserveMetadataExporter(app, self)
        
        // Insert exporter into `InterfaceExporterStorage`
        app.registerExporter(exporter: loggerExporter)
        
        // Write configuration to the storage
        app.storage.set(LoggingStorageKey.self, to: LoggingStorageValue(logger: app.logger, configuration: self))
        
        // Execute configuration function of LogHandlers
        self.configureLogHandlers()
        
        // Bootstrap the logging system
        LoggingSystem.bootstrap { label in
            MultiplexLogHandler(
                self.logHandlers.map { logHandler in
                    logHandler(label)
                }
            )
        }
    }
}
