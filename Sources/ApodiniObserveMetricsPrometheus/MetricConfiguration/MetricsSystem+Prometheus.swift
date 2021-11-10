//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniObserve
import Metrics
import CoreMetrics
import Prometheus

public extension MetricsSystem {
    /// Override the `.prometheus()` function of the `MetricsSystem` since `MultiplexMetricsHandler` are allowed, those are not currently supported by `SwiftPrometheus`
    static func prometheus() throws -> PrometheusClient {
        if let prometheusFactory = self.factory as? PrometheusWrappedMetricsFactory {
            return prometheusFactory.client
        }
        
        guard let prometheusFactory =
                MetricsConfiguration
                    .factories
                    .first(where: { ($0 as? PrometheusWrappedMetricsFactory) != nil })
                    as? PrometheusWrappedMetricsFactory else {
            throw PrometheusError.prometheusFactoryNotBootstrapped(bootstrappedWith: "\(self.factory)")
        }
        
        return prometheusFactory.client
    }
}
