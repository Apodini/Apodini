//
//  LoggerConfiguration.swift
//
//
//  Created by Philipp Zagar on 06.06.21.
//
import Foundation
import Logging
import Apodini

/// A `Configuration` for the `Logger`.
public final class LoggerConfiguration: Configuration, InterfaceExporter {
    internal let logLevel: Logger.Level
    internal let logHandlers: [LogHandler]
    
    /// initalize `LoggerConfiguration` with the `logLevel` and the to be used backend `logHandlers`
    public init(logLevel: Logger.Level, logHandlers: LogHandler...) {
        self.logLevel = logLevel
        self.logHandlers = logHandlers
    }

    /// Configure application
    public func configure(_ app: Application) {
        app.storage.set(LoggingStorageKey.self, to: LoggingStorageValue(logger: app.logger, configuration: self))
        
        // Bootstrap the logging system
        LoggingSystem.bootstrap { label in
            MultiplexLogHandler(
                self.logHandlers
            )
        }
    }
    
    public func export<H>(_ endpoint: Endpoint<H>) -> () where H : Handler {
        <#code#>
    }
    
    public func export<H>(blob endpoint: Endpoint<H>) -> () where H : Handler, H.Response.Content == Blob {
        <#code#>
    }
}

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
