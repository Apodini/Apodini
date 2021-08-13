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
/// A wrapped version of the ``PromSummary`` of SwiftPrometheus
/// Provides raw access to the metric types of SwiftPrometheus which are closly related to Prometheus itself, unlike swift-metrics
public struct PrometheusSummary<T: DoubleRepresentable, U: SummaryLabels>: DynamicProperty {
    /// The ``Storage`` of the ``Application``
    @Environment(\.storage)
    var storage: Storage
    
    let label: String
    let type: T.Type
    let helpText: String?
    let capacity: Int
    let quantiles: [Double]
    let labels: U.Type
    
    let prometheusLabelSanitizer: PrometheusLabelSanitizer
    
    public init(_ label: String,
                type: T.Type = Int64.self as! T.Type,
                helpText: String? = nil,
                capacity: Int = Prometheus.defaultSummaryCapacity,
                quantiles: [Double] = Prometheus.defaultQuantiles,
                labels: U.Type = DimensionSummaryLabels.self as! U.Type) {
        self.label = label
        self.type = type
        self.helpText = helpText
        self.capacity = capacity
        self.quantiles = quantiles
        self.labels = labels
        
        self.prometheusLabelSanitizer = PrometheusLabelSanitizer()
    }
    
    public init(_ label: String) where T == Int64, U == DimensionSummaryLabels {
        // Need to pass one additional value to not result in infinite recursion
        self.init(label, helpText: nil)
    }
    
    public var wrappedValue: PromSummary<T, U> {
        guard let prometheus = try? MetricsSystem.prometheus() else {
            fatalError(MetricsError.prometheusNotYetBootstrapped.rawValue)
        }
        
        // No need to cache the created Metric since the `createSummary()` does exactly that
        return prometheus.createSummary(
            forType: self.type,
            named: self.prometheusLabelSanitizer.sanitize(self.label),
            helpText: self.helpText,
            capacity: self.capacity,
            quantiles: self.quantiles,
            labels: self.labels
        )
    }
}
