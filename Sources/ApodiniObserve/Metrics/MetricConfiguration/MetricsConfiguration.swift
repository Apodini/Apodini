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

public class MetricsConfiguration: Configuration {
    let metricHandlerConfigurations: [MetricHandlerConfiguration]
    let systemMetricsConfiguration: SystemMetricsConfiguration
    
    public init(handlerConfiguration: MetricHandlerConfiguration..., systemMetricsConfiguration: SystemMetricsConfiguration = .default) {
        self.metricHandlerConfigurations = handlerConfiguration
        self.systemMetricsConfiguration = systemMetricsConfiguration
    }
    
    public func configure(_ app: Application) {
        // Bootstrap all passed MetricHandlers
        MetricsSystem.bootstrap(
            MultiplexMetricsHandler(
                factories: self.metricHandlerConfigurations.map { $0.factory }
            )
        )
        
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
            
            // Sadly the interval property is internal :/ (maybe create a PR for SwiftPrometheus that makes these properties public?)
            //app.logger.info("System metrics collected in an interval of \(configuration.interval)")
        }
        
        // Write configuration to the storage
        app.storage.set(MetricsStorageKey.self, to: MetricsStorageValue(configuration: self))
    }
}
