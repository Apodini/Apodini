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
import Prometheus

public final class MetricsConfiguration: Configuration {
    /// The storage key for Metrics-related information
    public struct MetricsStorageKey: StorageKey {
        public typealias Value = MetricsStorageValue
    }

    /// The storage value for Metrics-related information.
    public struct MetricsStorageValue {
        public let prometheus: PrometheusClient
        public let configuration: MetricsConfiguration

        internal init(prometheus: PrometheusClient, configuration: MetricsConfiguration) {
            self.prometheus = prometheus
            self.configuration = configuration
        }
    }
    
    public enum ConfigurationDefaults {
        public static let prometheusEndpoint: String = "metrics"
    }
    
    let prometheusEndpoint: String
    let systemMetricsPollingInterval: DispatchTimeInterval
    
    public init(prometheusEndpoint: String = ConfigurationDefaults.prometheusEndpoint,
                systemMetricsPollingInterval: DispatchTimeInterval = .seconds(1)) {
        self.prometheusEndpoint = prometheusEndpoint.hasPrefix("/") ? prometheusEndpoint : "/\(prometheusEndpoint)"
        self.systemMetricsPollingInterval = systemMetricsPollingInterval
    }
    
    public func configure(_ app: Application) {
        // Bootstrap MetricsSystem with PrometheusClient
        let prometheus = PrometheusClient()
        // Just default config for now
        // A LabelSanitizer used to sanitize metric names to valid Prometheus values. A default implementation is provided.
        // The Prometheus metric type to use for swift-metrics' Timer. Can be a Histogram or a Summary. Note that when using Histogram, preferredDisplayUnit will not be observed.
        // Default buckets for use by aggregating swift-metrics Recorder instances.
        MetricsSystem.bootstrap(PrometheusMetricsFactory(client: prometheus, configuration: PrometheusMetricsFactory.Configuration()))
        
        // Bootstrap System Metrics collection
        MetricsSystem.bootstrapSystemMetrics(
            .init(
                pollInterval: self.systemMetricsPollingInterval,
                // Here we could provide a custom data provider that collects metrics, just works with Linux systems for now
                dataProvider: nil,
                labels: .init(
                    prefix: "process_",
                    virtualMemoryBytes: "virtual_memory_bytes",
                    residentMemoryBytes: "resident_memory_bytes",
                    startTimeSeconds: "start_time_seconds",
                    cpuSecondsTotal: "cpu_seconds_total",
                    maxFds: "max_fds",
                    openFds: "open_fds"
                ))
        )
        
        // Write configuration to the storage
        app.storage.set(MetricsStorageKey.self, to: MetricsStorageValue(prometheus: prometheus, configuration: self))
        
        // Register Prometheus serving endpoint
        app.vapor.app.get(self.prometheusEndpoint.pathComponents) { req -> EventLoopFuture<String> in
            let promise = req.eventLoop.makePromise(of: String.self)
            
            DispatchQueue.global().async {
                do {
                    prometheus.collect(into: promise)
                } catch {
                    promise.fail(error)
                }
            }
            
            return promise.futureResult
        }
        
        // Inform developer about serving on the configured endpoint
        app.logger.info("Prometheus Metrics served on \(self.prometheusEndpoint)")
        app.logger.info("System metrics collected in an interval of \(self.systemMetricsPollingInterval)")
    }
}
