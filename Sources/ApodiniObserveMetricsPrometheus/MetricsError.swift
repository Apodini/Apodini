//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniObserve

/// Possible error types during the `ApodiniMetric` types process
public extension MetricsError {
    /// Error in which Prometheus wasn't bootstrapped yet
    static let prometheusNotYetBootstrapped: MetricsError = {
        .init(rawValue: "Metric Type was created without bootstrapping the MetricsSystem first")
    }()
}
