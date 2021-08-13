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

public extension MetricPullHandlerConfiguration {
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
