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

/// A wrapped version of the ``PromSummary`` of SwiftPrometheus
/// Provides raw access to the metric types of SwiftPrometheus which are closly related to Prometheus itself, unlike swift-metrics
@propertyWrapper
public struct ApodiniPrometheusSummary<T: DoubleRepresentable, U: SummaryLabels>: DynamicProperty {
    @State
    private var builtSummary: PromSummary<T, U>?
    
    let label: String
    let type: T.Type
    let helpText: String?
    let capacity: Int
    let quantiles: [Double]
    let withLabelType: U.Type
    
    let prometheusLabelSanitizer: PrometheusLabelSanitizer
    
    public init(label: String,
                type: T.Type = Int64.self as! T.Type,
                helpText: String? = nil,
                capacity: Int = Prometheus.defaultSummaryCapacity,
                quantiles: [Double] = Prometheus.defaultQuantiles,
                withLabelType: U.Type = DimensionSummaryLabels.self as! U.Type) {
        self.label = label
        self.type = type
        self.helpText = helpText
        self.capacity = capacity
        self.quantiles = quantiles
        self.withLabelType = withLabelType
        
        self.prometheusLabelSanitizer = PrometheusLabelSanitizer()
    }
    
    public init(label: String) where T == Int64, U == DimensionSummaryLabels {
        // Need to pass one additional value to not result in infinite recursion
        self.init(label: label, helpText: nil)
    }
    
    public var wrappedValue: PromSummary<T, U> {
        if self.builtSummary == nil {
            guard let prometheus = try? MetricsSystem.prometheus() else {
                fatalError(MetricsError.prometheusNotYetBootstrapped.rawValue)
            }

            self.builtSummary = prometheus.createSummary(
                forType: self.type,
                named: self.prometheusLabelSanitizer.sanitize(self.label),
                helpText: self.helpText,
                capacity: self.capacity,
                quantiles: self.quantiles,
                labels: self.withLabelType
            )
        }
        
        guard let builtSummary = self.builtSummary else {
            fatalError("The Summary isn't built correctly!")
        }
        
        return builtSummary
    }
}
