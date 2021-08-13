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

public protocol MetricHandlerConfiguration {
    var factory: MetricsFactory { get }
}

public struct MetricPullHandlerConfiguration: MetricHandlerConfiguration {
    public let factory: MetricsFactory
    public let endpoint: String
    public let collect: (EventLoopPromise<String>) -> EventLoopFuture<String>
    
    public init(factory: MetricsFactory, endpoint: String, collect: @escaping (EventLoopPromise<String>) -> EventLoopFuture<String>) {
        self.factory = factory
        self.endpoint = endpoint
        self.collect = collect
    }
}

public struct MetricPushHandlerConfiguration: MetricHandlerConfiguration {
    public let factory: MetricsFactory
}

public enum SystemMetricsConfiguration {
    case on(configuration: SystemMetrics.Configuration)
    case off
    
    public static var `default`: SystemMetricsConfiguration =
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
