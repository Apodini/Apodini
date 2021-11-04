//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Metrics
import SystemMetrics
import NIO

/// Base protocol for a configuration of a ``MetricsHandler`` via ``ApodiniObserve``
public protocol MetricHandlerConfiguration {
    /// The factory which creates the `MetricsHandler`
    var factory: MetricsFactory { get }
}

/// A configuration for pull based `MetricsHandler`, so for example Prometheus
public struct MetricPullHandlerConfiguration: MetricHandlerConfiguration {
    /// The factory which creates the `MetricsHandler`
    public let factory: MetricsFactory
    /// The name of the web endpoint where the metrics can be pulled from
    public let endpoint: String
    /// Collects the metrics data from the `MetricsHandler` that is then provided via an endpoint to pull based `MetricsHandler`, so for example Prometheus
    public let collect: (EventLoopPromise<String>) -> EventLoopFuture<String>
    
    /// Inizializes a ``MetricPullHandlerConfiguration``
    /// - Parameters:
    ///   - factory: The `MetricsFactory` that should be used as a metrics backend
    ///   - endpoint: Name of the web endpoint where the metrics data is provided
    ///   - collect: A closure that collects the metrics data that is then provided via a web endpoint
    public init(factory: MetricsFactory, endpoint: String, collect: @escaping (EventLoopPromise<String>) -> EventLoopFuture<String>) {
        self.factory = factory
        self.endpoint = endpoint
        self.collect = collect
    }
}

/// A configuration for push based `MetricsHandler`
public struct MetricPushHandlerConfiguration: MetricHandlerConfiguration {
    /// The factory which creates the `MetricsHandler`
    public let factory: MetricsFactory
    
    /// Inizializes a ``MetricPushHandlerConfiguration``
    /// - Parameter factory: The `MetricsFactory` that should be used as a metrics backend
    public init(factory: MetricsFactory) {
        self.factory = factory
    }
}

/// Used to configure a `SystemMetrics.Configuration` via ``ApodiniObserve``
public enum SystemMetricsConfiguration {
    /// System metrics will be collected with a certain `SystemMetrics.Configuration`
    case on(configuration: SystemMetrics.Configuration)    // swiftlint:disable:this identifier_name
    /// Sytem metrics will not be collected
    case off
    
    /// System metrics will be collected with a default `SystemMetrics.Configuration` which collect only Linux metrics with default labels in an one second interval
    public static let `default`: SystemMetricsConfiguration =
        .on(
            configuration: .init(
                pollInterval: .seconds(1),
                // Without custom dataProvider, only Linux metrics are supported
                dataProvider: nil,
                labels: .init(
                    prefix: "process_",
                    virtualMemoryBytes: "virtual_memory_bytes",
                    residentMemoryBytes: "resident_memory_bytes",
                    startTimeSeconds: "start_time_seconds",
                    cpuSecondsTotal: "cpu_seconds_total",
                    maxFds: "max_fds",
                    openFds: "open_fds"
                )
            )
        )
}
