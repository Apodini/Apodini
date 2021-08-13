//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniObserve
import Metrics
import Prometheus

@propertyWrapper
/// A wrapped version of the ``PromHistogram`` of SwiftPrometheus
/// Provides raw access to the metric types of SwiftPrometheus which are closly related to Prometheus itself, unlike swift-metrics
public struct PrometheusHistogram<T: DoubleRepresentable, U: HistogramLabels>: DynamicProperty {
    /// The ``Storage`` of the ``Application``
    @Environment(\.storage)
    var storage: Storage
    
    let label: String
    let type: T.Type
    let helpText: String?
    let buckets: Buckets
    let labels: U.Type
    
    let prometheusLabelSanitizer: PrometheusLabelSanitizer
    
    public init(_ label: String,
                type: T.Type = Int64.self as! T.Type,
                helpText: String? = nil,
                buckets: Buckets = .defaultBuckets,
                labels: U.Type = DimensionHistogramLabels.self as! U.Type) {
        self.label = label
        self.type = type
        self.helpText = helpText
        self.buckets = buckets
        self.labels = labels
        
        self.prometheusLabelSanitizer = PrometheusLabelSanitizer()
    }
    
    public init(_ label: String) where T == Int64, U == DimensionHistogramLabels {
        // Need to pass one additional value to not result in infinite recursion
        self.init(label, helpText: nil)
    }
    
    public var wrappedValue: PromHistogram<T, U> {
        guard let prometheus = try? MetricsSystem.prometheus() else {
            fatalError(MetricsError.prometheusNotYetBootstrapped.rawValue)
        }

        // No need to cache the created Metric since the `createHistogram()` does exactly that
        return prometheus.createHistogram(
            forType: self.type,
            named: self.prometheusLabelSanitizer.sanitize(self.label),
            helpText: self.helpText,
            buckets: self.buckets,
            labels: self.labels
        )
    }
}
