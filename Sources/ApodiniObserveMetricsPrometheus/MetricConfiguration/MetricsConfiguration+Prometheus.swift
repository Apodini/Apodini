//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniObserve

/// Extension that allows for easier setup of the ``MetricsConfiguration`` for a Prometheus backend
public extension MetricsConfiguration {
    /// Convencience init for a Prometheus backend
    convenience init(prometheusHandlerConfiguration: MetricPullHandlerConfiguration = .defaultPrometheus,
                     systemMetricsConfiguration: SystemMetricsConfiguration = .default) {
        self.init(handlerConfiguration: prometheusHandlerConfiguration, systemMetricsConfiguration: systemMetricsConfiguration)
    }
}
