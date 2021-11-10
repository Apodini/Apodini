//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniVaporSupport
import Metrics
import SystemMetrics

/// The `Configuration` for the `ApodiniMetric` types.
public class MetricsConfiguration: Configuration {
    /// The storage key for Metrics-related information
    public struct MetricsStorageKey: StorageKey {
        public typealias Value = MetricsStorageValue
    }

    /// The storage value for Metrics-related information.
    public struct MetricsStorageValue {
        /// The stored `MetricsConfiguration`
        public let configuration: MetricsConfiguration
        
        /// Creates the storage value that relates to a ``MetricsStorageKey``
        /// - Parameter configuration: The stored ``MetricsConfiguration``
        internal init(configuration: MetricsConfiguration) {
            self.configuration = configuration
        }
    }
    
    /// Holds the configured `MetricsFactory`'s
    let metricHandlerConfigurations: [MetricHandlerConfiguration]
    /// Holds the configured `SystemMetrics.Configuration`
    let systemMetricsConfiguration: SystemMetricsConfiguration
    /// Publicly store the used `MetricsFactory`
    public static var factories: [MetricsFactory] = []
    
    /// Initializes the ``MetricsConfiguration`` with an arbitrary number of ``MetricHandlerConfiguration`` as well as a single ``SystemMetricsConfiguration``
    /// - Parameters:
    ///   - handlerConfiguration: Arbitrary number of ``MetricHandlerConfiguration`` that specify the to be used metric backends
    ///   - systemMetricsConfiguration: Specifies the collection of system metrics via a ``SystemMetricsConfiguration``
    public init(handlerConfiguration: MetricHandlerConfiguration..., systemMetricsConfiguration: SystemMetricsConfiguration = .default) {
        self.metricHandlerConfigurations = handlerConfiguration
        self.systemMetricsConfiguration = systemMetricsConfiguration
        
        Self.factories = handlerConfiguration.map { metricsHandler in
            metricsHandler.factory
        }
    }
    
    /// Configures the `Application` for the `ApodiniMetric` types
    /// - Parameter app: The to be configured `Application`
    public func configure(_ app: Application) {
        // Bootstrap all passed MetricHandlers
        MetricsSystem.bootstrap(
            MultiplexMetricsHandler(
                factories: self.metricHandlerConfigurations.map { $0.factory }
            )
        )
        
        if !app.checkRegisteredExporter(exporterType: ObserveMetadataExporter.self) {
            // Instanciate exporter
            let metadataExporter = ObserveMetadataExporter(app, self)
            
            // Insert exporter into `InterfaceExporterStorage`
            app.registerExporter(exporter: metadataExporter)
        }
        
        // For Pull-based MetricHandlers, the developer is required to provide an
        // web endpoint and a closure that returns the to be exposed metrics data
        // at the previously provided web endpoint
        self.metricHandlerConfigurations.forEach { metricHandlerConfiguration in
            if let metricPullHandlerConfiguration = metricHandlerConfiguration as? MetricPullHandlerConfiguration {
                let endpoint = metricPullHandlerConfiguration.endpoint.hasPrefix("/")
                                ? metricPullHandlerConfiguration.endpoint
                                : "/\(metricPullHandlerConfiguration.endpoint)"
                
                app.vapor.app.get(endpoint.pathComponents) { req -> EventLoopFuture<String> in
                    metricPullHandlerConfiguration.collect(req.eventLoop.makePromise(of: String.self))
                }
                
                // Inform developer about which MetricsHandler serves the metrics data on what endpoint
                app.logger.info("Metrics data of \(metricPullHandlerConfiguration.factory.self) served on \(metricPullHandlerConfiguration.endpoint)")
            }
        }
        
        if case .on(let configuration) = self.systemMetricsConfiguration {
            MetricsSystem.bootstrapSystemMetrics(
                configuration
            )
            
            // Sadly, the interval property is internal, maybe this will change in future versions
            //app.logger.info("System metrics collected in an interval of \(configuration.interval)")
        }
        
        // Write configuration to the storage
        app.storage.set(MetricsStorageKey.self, to: MetricsStorageValue(configuration: self))
    }
}
