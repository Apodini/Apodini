//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// Possible error types during the `ApodiniMetric` types process
public enum MetricsError: String {
    /// Error in which Prometheus wasn't bootstrapped yet
    case prometheusNotYetBootstrapped = """
    Metric Type was created without bootstrapping the MetricsSystem first
    """
    
    /// Error in which a Metric was accessed before it was initialized
    case metricAccessedBeforeBeeingInitialized = """
    Wrapped value of metric was accessed before beeing initialized
    """
}
