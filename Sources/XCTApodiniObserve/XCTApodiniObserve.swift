//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

#if DEBUG || RELEASE_TESTING
import Apodini
@testable import ApodiniObserve
@testable import CoreMetrics

/// ApodiniObserve test helpers
public enum XCTApodiniObserve {
    // Copied from the source code of ApodiniObserve to bootstrap the MetricsSystem internally
    // (required for the tests, as the MetricsSystem only allows to be configured once per process)
    /// Test helper to configure Metrics
    public static func configureMetrics(_ app: Apodini.Application, metricsConfiguration: MetricsConfiguration) -> Apodini.Application {
        // Bootstrap all passed MetricHandlers
        MetricsSystem.bootstrapInternal(
            MultiplexMetricsHandler(
                factories: metricsConfiguration.metricHandlerConfigurations.map { $0.factory }
            )
        )
        
        if !app.checkRegisteredExporter(exporterType: ObserveMetadataExporter.self) {
            // Instanciate exporter
            let metadataExporter = ObserveMetadataExporter(app, metricsConfiguration)
            
            // Insert exporter into `InterfaceExporterStorage`
            app.registerExporter(exporter: metadataExporter)
        }
        
        metricsConfiguration.metricHandlerConfigurations.forEach { metricHandlerConfiguration in
            if let metricPullHandlerConfiguration = metricHandlerConfiguration as? MetricPullHandlerConfiguration {
                let endpoint = metricPullHandlerConfiguration.endpoint.hasPrefix("/")
                                ? metricPullHandlerConfiguration.endpoint
                                : "/\(metricPullHandlerConfiguration.endpoint)"
                app.httpServer.registerRoute(.GET, endpoint.httpPathComponents) { req -> EventLoopFuture<String> in
                    metricPullHandlerConfiguration.collect(req.eventLoop.makePromise(of: String.self))
                }
                
                // Inform developer about which MetricsHandler serves the metrics data on what endpoint
                app.logger.info("Metrics data of \(metricPullHandlerConfiguration.factory.self) served on \(metricPullHandlerConfiguration.endpoint)")
            }
        }
        
        // Write configuration to the storage
        app.storage.set(MetricsConfiguration.MetricsStorageKey.self,
                        to: MetricsConfiguration.MetricsStorageValue(configuration: metricsConfiguration))
        
        return app
    }
}
#endif
