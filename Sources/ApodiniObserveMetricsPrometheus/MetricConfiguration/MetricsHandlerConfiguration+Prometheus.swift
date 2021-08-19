//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniObserve
import Metrics
import Prometheus

/// Extension that allows for easier setup of the ``MetricsConfiguration`` for a Prometheus backend by providing a default configuration value
public extension MetricPullHandlerConfiguration {
    /// Default configuration for Prometheus
    static let `defaultPrometheus`: MetricPullHandlerConfiguration =
        MetricPullHandlerConfiguration(
            factory: PrometheusMetricsFactory(
                client: PrometheusClient(),
                configuration: PrometheusMetricsFactory.Configuration()),
            endpoint: "/metrics",
            collect: { promise in
                DispatchQueue.global().async {
                    do {
                        try MetricsSystem.prometheus().collect(into: promise)
                    } catch {
                        promise.fail(error)
                    }
                }
                
                return promise.futureResult
            }
        )
}
