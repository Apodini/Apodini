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
public final class LoggerConfiguration: Configuration {
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
        
        /// Instanciate exporter
        let loggerExporter = LoggerInterfaceExporter(app, self)
        
        /// Insert exporter into `InterfaceExporterStorage`
        app.registerExporter(exporter: loggerExporter)
    }
}

public final class LoggerInterfaceExporter: InterfaceExporter, TruthAnchor {
    public struct Metadata: EnvironmentAccessible {
        public var value: BlackboardMetadata
    }
    
    public struct BlackboardMetadata {
        public let endpointName: String
        public let endpointParameters: EndpointParameters
        public let endpointParametersOther: EndpointParameters
        public let operation: Apodini.Operation
        public let absolutePath: [EndpointPath]
        public let endpointPathComponents: EndpointPathComponents
        public let endpointPathComponentsHTTP: EndpointPathComponentsHTTP
        public let context: Context
        public let anyEndpointSource: AnyEndpointSource
        public let handleReturnType: HandleReturnType
        public let responseType: ResponseType
        public let serviceType: ServiceType
        //public let version: Version
        //public let relationship: RelationshipDestination
    }
    
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
    
    private func exportOntoBlackboard<H>(_ endpoint: Endpoint<H>) -> () where H: Handler {
        let factory = endpoint[DelegateFactoryBasis<H>.self]

        let delegate = factory.delegate
        
        let blackboardMetadata = BlackboardMetadata(
                                    endpointName: endpoint.description,
                                    endpointParameters: endpoint[EndpointParameters.self],
                                    endpointParametersOther: endpoint.parameters,
                                    operation: endpoint[Operation.self],
                                    absolutePath: endpoint.absolutePath,
                                    endpointPathComponents: endpoint[EndpointPathComponents.self],
                                    endpointPathComponentsHTTP: endpoint[EndpointPathComponentsHTTP.self],
                                    context: endpoint[Context.self],
                                    anyEndpointSource: endpoint[AnyEndpointSource.self],
                                    handleReturnType: endpoint[HandleReturnType.self],
                                    responseType: endpoint[ResponseType.self],
                                    serviceType: endpoint[ServiceType.self]
                                    
                                    //version: endpoint[Version.self],
                                    //relationship: endpoint[RelationshipSourceContextKey.self]
                                )

        delegate.environment(\Metadata.value, blackboardMetadata)
        
        print(endpoint)
        
        print("a")
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
