//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

enum MetricsError: String {
    case prometheusNotYetBootstrapped = """
    Metric Type was created without bootstrapping the MetricsSystem first
    """
    
    case metricAccessedBeforeBeeingInitialized = """
    Wrapped value of metric was accessed before beeing initialized
    """
}
